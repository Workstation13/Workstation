SUBSYSTEM_DEF(supply)
	name = "Supply"
	wait = 0.5 MINUTES // Each fire is one account transaction, so pay the stipend in larger, less frequent chunks.
	priority = SS_PRIORITY_SUPPLY
	//Initializes at default time
	flags = SS_NO_TICK_CHECK

	// Supply pack costs and export values are in supply points. Money moves in local currency,
	// converted with GLOB.using_map.supply_price_multiplier (see to_currency()).
	var/points_per_process = 15
	var/points_per_slip = 2
	/// Income per source in local currency, for the statistics screen.
	var/point_sources = list()
	/// Income in local currency not yet deposited, e.g. while the economy is not set up yet.
	var/pending_income = 0
	/// Machine ID shown on supply transactions.
	var/transaction_source = "Supply Management"
	var/pointstotalsum = 0
	var/pointstotal = 0
	//control
	var/ordernum
	var/list/shoppinglist = list()
	var/list/requestlist = list()
	var/list/donelist = list()
	var/list/master_supply_list = list()
	//shuttle movement
	var/movetime = 0
	var/datum/shuttle/autodock/ferry/supply/shuttle
	var/list/point_source_descriptions = list(
		"time" = "Base station supply",
		"manifest" = "From exported manifests",
		"crate" = "From exported crates",
		"gep" = "From uploaded survey data",
		"anomaly" = "From scanned and categorized anomalies",
		"animal" = "From captured exotic alien fauna",
		"machinery" = "From exported machinery",
		"electronics" = "From exported electronics",
		"gas" = "From exported gases",
		"liquid" = "From exported chemicals and liquid fuels",
		"firearms" = "From exported firearms",
		"foodstuffs" = "From exported foodstuffs",
		"clothing" = "From exported apparel",
		"miscellaneous" = "From other miscellaneous exports",
		"fine" = "From fines",
		"total" = "Total" // If you're adding additional point sources, add it here in a new line. Don't forget to put a comma after the old last line.
	)
	var/list/fines = list()
	var/base_fine_delay = 0 MINUTES
	var/fine_delay = 0
	var/last_fine = 0
	var/resell_penalty = 0.5 //multiplier for price of miscellaneous items sold
	var/demand_limit = 400 //amount of supply points that can be gotten from each category of miscellaneous items

/datum/controller/subsystem/supply/Initialize(start_uptime)
	ordernum = rand(1,9000)

	//Build master supply list
	var/singleton/hierarchy/supply_pack/root = GET_SINGLETON(/singleton/hierarchy/supply_pack)
	for (var/singleton/hierarchy/supply_pack/sp in root.children)
		if(sp.is_category())
			for(var/singleton/hierarchy/supply_pack/spc in sp.get_descendents())
				spc.setup()
				master_supply_list += spc

	for (var/material/mat in SSmaterials.materials)
		if(mat.sale_price > 0)
			point_source_descriptions[mat.display_name] = "From exported [mat.display_name]"
	fine_delay = base_fine_delay + rand(-base_fine_delay / 5, base_fine_delay / 5)

// Just add money over time.
/datum/controller/subsystem/supply/fire()
	add_points_from_source(points_per_process, "time")
	deposit_income("Supply stipend")
	if (world.time > fine_delay + last_fine)
		fine_delay = base_fine_delay + rand(-base_fine_delay / 5, base_fine_delay / 5)
		last_fine = world.time
		issue_fines()

/datum/controller/subsystem/supply/UpdateStat(time)
	if (PreventUpdateStat(time))
		return ..()
	..("Balance: [get_balance()]")


//Supply-related helper procs.

/// The account that pays for supply orders and receives export income.
/datum/controller/subsystem/supply/proc/get_account()
	RETURN_TYPE(/datum/money_account)
	return department_accounts["Supply"] || station_account

/datum/controller/subsystem/supply/proc/get_balance()
	var/datum/money_account/account = get_account()
	return account ? account.money : 0

/// Converts an amount of supply points to local currency.
/datum/controller/subsystem/supply/proc/to_currency(amount)
	return round(amount * GLOB.using_map.supply_price_multiplier)

/// Records income of `amount` supply points from `source`. Call deposit_income() to pay it into the account.
/datum/controller/subsystem/supply/proc/add_points_from_source(amount, source, safe = FALSE) //use safe if interacting with the demand system
	if (safe)
		amount = min(amount, demand_limit)
	var/money = to_currency(amount)
	pending_income += money
	point_sources[source] += money
	point_sources["total"] += money

/datum/controller/subsystem/supply/proc/deposit_income(purpose)
	var/datum/money_account/account = get_account()
	if(!account || pending_income <= 0)
		return
	if(account.deposit(pending_income, purpose, transaction_source))
		pending_income = 0

/// Charges `amount` supply points to the supply account. Returns TRUE on success.
/// With `partial`, charges whatever the account can afford instead of failing.
/datum/controller/subsystem/supply/proc/charge(amount, purpose, partial = FALSE)
	var/datum/money_account/account = get_account()
	if(!account)
		return FALSE
	var/money = to_currency(amount)
	if(partial)
		money = min(money, account.money)
	if(money <= 0)
		return FALSE
	return account.withdraw(money, purpose, transaction_source)

/// Refunds `amount` supply points to the supply account.
/datum/controller/subsystem/supply/proc/refund(amount, purpose)
	var/datum/money_account/account = get_account()
	if(!account)
		return FALSE
	return account.deposit(to_currency(amount), purpose, transaction_source)

	//To stop things being sent to centcomm which should not be sent to centcomm. Recursively checks for these types.
/datum/controller/subsystem/supply/proc/forbidden_atoms_check(atom/A)
	if (istype(A, /mob/living))
		var/mob/living/mob = A
		if ((istype(mob, /mob/living/simple_animal/hostile/human) || mob.mind) && mob.health > 0)
			return TRUE
	if (istype(A, /obj/item/disk/nuclear))
		return TRUE
	if (istype(A, /obj/machinery/nuclearbomb))
		return TRUE
	if (istype(A, /obj/machinery/tele_beacon))
		return TRUE

	for(var/i=1, i<=length(A.contents), i++)
		var/atom/B = A.contents[i]
		if(.(B))
			return TRUE

/datum/controller/subsystem/supply/proc/issue_fines()
	for (var/fine in fines)
		var/amount = fines[fine]
		if (amount > 0)
			add_points_from_source(-amount, "fine")
			fines[fine] = 0
		var/list/fine_book = typesof(/obj/item/paper/fine)
		for (var/i in fine_book)
			i = new i
			if (istype(i, /obj/item/paper/fine))
				var/obj/item/paper/fine/fine_letter = i
				if (fine_letter.subject == fine)
					fine_letter.update_fine(to_currency(amount))
					send_fax_loop(fine_letter, fine_letter.destinations, fine_letter.origin)
					break
			qdel(i)

/datum/controller/subsystem/supply/proc/add_fine(type, amount)
	fines[type] += amount

/datum/controller/subsystem/supply/proc/get_supply_value(initial_value, sale_type)
	return initial_value * resell_penalty * get_demand(sale_type) / GLOB.using_map.supply_price_multiplier

/datum/controller/subsystem/supply/proc/get_demand(sale) //penalizes selling the same type of thing repeatedly
	return clamp(1 - point_sources[sale] / to_currency(demand_limit), 0, 1)

/datum/controller/subsystem/supply/proc/sell()
	var/list/material_count = list()

	for(var/area/subarea in shuttle.shuttle_area)
		for(var/atom/movable/AM in subarea)
			if(AM.anchored)
				continue
			if(istype(AM, /obj/structure/closet/crate))
				var/obj/structure/closet/crate/CR = AM
				callHook("sell_crate", list(CR, subarea))
				add_points_from_source(CR.points_per_crate, "crate")
				var/find_slip = 1

				for(var/atom in CR)
					// Sell manifests
					var/atom/A = atom
					if(find_slip && istype(A,/obj/item/paper/manifest))
						var/obj/item/paper/manifest/slip = A
						if(!slip.is_copy && slip.stamped && length(slip.stamped)) //Any stamp works.
							add_points_from_source(points_per_slip, "manifest")
							find_slip = 0
						continue

					// Sell materials
					if(istype(A, /obj/item/stack/material))
						var/obj/item/stack/material/P = A
						if(P.material && P.material.sale_price > 0)
							material_count[P.material.display_name] += P.get_amount() * P.material.sale_price * P.matter_multiplier
						if(P.reinf_material && P.reinf_material.sale_price > 0)
							material_count[P.reinf_material.display_name] += P.get_amount() * P.reinf_material.sale_price * P.matter_multiplier * 0.5
						continue

					// Must sell ore detector disks in crates
					if(istype(A, /obj/item/disk/survey))
						var/obj/item/disk/survey/D = A
						add_points_from_source(round(D.Value() * 0.05), "gep")

					else
						sell_misc_item(A)

			// Sell artefacts (in anomaly cages)
			if (istype(AM, /obj/machinery/anomaly_container))
				var/obj/machinery/anomaly_container/AC = AM
				var/points_per_anomaly = 10
				callHook("sell_anomalycage", list(AC, subarea))
				if (AC.contained)
					var/obj/machinery/artifact/C = AC.contained
					var/list/my_effects = list()
					if (C.my_effect)
						var/datum/artifact_effect/eone = C.my_effect
						my_effects += eone
					if (C.secondary_effect)
						var/datum/artifact_effect/etwo = C.secondary_effect
						my_effects += etwo
					//Different effects and trigger combos give different rewards

					if (AC.attached_paper) //Needs to have a scan sheet of the anomaly to the container.
						if (istype(AC.attached_paper, /obj/item/paper/anomaly_scan))
							var/obj/item/paper/anomaly_scan/P = AC.attached_paper
							if (!P.is_copy)
								for (var/datum/artifact_effect/E in my_effects)
									switch (E.effect_type)
										if (EFFECT_UNKNOWN, EFFECT_PSIONIC)
											points_per_anomaly += 10
										if (EFFECT_ENERGY, EFFECT_ELECTRO)
											points_per_anomaly += 20
										if (EFFECT_ORGANIC, EFFECT_SYNTH)
											points_per_anomaly += 30
										if (EFFECT_BLUESPACE, EFFECT_PARTICLE)
											points_per_anomaly += 40
										else
											points_per_anomaly += 10
											//In case there's ever a broken artifact, it's still worth SOMETHING
									switch (E.trigger.trigger_type)
										if (TRIGGER_SIMPLE)
											points_per_anomaly += 5
										if (TRIGGER_COMPLEX)
											points_per_anomaly += 10
										else
											points_per_anomaly += 2

								add_points_from_source(points_per_anomaly, "anomaly")

			//Only for animals in stasis cages.
			if (istype(AM, /obj/machinery/stasis_cage))
				var/obj/machinery/stasis_cage/SC = AM
				var/points_per_animal = 10
				callHook("sell_animal", list(SC, subarea))
				if (SC.contained)
					var/mob/living/simple_animal/CA = SC.contained
					if (istype(CA, /mob/living/simple_animal/hostile/human))
						continue
					if (istype(CA, /mob/living/simple_animal/hostile))
						points_per_animal *= 2
					if (istype(CA, /mob/living/simple_animal/hostile/retaliate/beast))
						points_per_animal *= 2
					if (CA.stat != DEAD) //Alive gives more.
						points_per_animal *= 2

					qdel(SC.contained)
					add_points_from_source(points_per_animal, "animal")

			if (istype (AM, /obj/machinery/artifact)) //unsecured anomaly
				add_fine("anomaly", 150)
			else if (istype(AM, /obj/machinery))
				sell_machinery(AM)

			if (!istype(AM, /obj/item) && !ismob(AM)) //items already include the reagents inside in their price and you probably can't extract chemicals from a body
				sell_liquid(AM)

			if (ishuman(AM) || istype(AM, /mob/living/simple_animal/hostile/human)) //unsolicited human remains
				add_fine("corpse", 100)
				log_and_message_admins("corpse of [AM] sent on cargo drone")
			else if (isliving(AM)) //unsecured animal/carcass
				add_fine("carcass", rand(20, 60))

			qdel(AM)

	if(length(material_count))
		for(var/material_type in material_count)
			add_points_from_source(material_count[material_type], material_type)

	deposit_income("Export sale")

	if(length(material_count))
		for(var/material_type in material_count)
			add_points_from_source(material_count[material_type], material_type)

	deposit_income("Export sale")

/datum/controller/subsystem/supply/proc/sale_type(produce)
	. = "miscellaneous"
	if (istype(produce, /obj/machinery))
		. = "machinery"
	if (istype(produce, /obj/item/gun))
		. = "firearms"
	if (istype(produce, /obj/structure))
		. = "furniture"
	if (istype(produce, /obj/item/stock_parts))
		. = "electronics"
	if (istype(produce, /obj/item/modular_computer))
		. = "electronics"
	if (istype(produce, /obj/item/organ) || istype(produce, /obj/item/reagent_containers/food/snacks/organ))
		. = "organs"
	if (istype(produce, /obj/item/reagent_containers/food))
		. = "foodstuffs"
	if (istype(produce, /obj/item/clothing))
		. = "clothing"

/datum/controller/subsystem/supply/proc/sell_misc_item(atom/movable/produce)
	var/sale = "miscellaneous"
	var/value = 0
	value = (get_value(produce) - sell_liquid(produce)) //items include their reagents in their price, so they must be separated
	sale = sale_type(produce)
	switch (sale)
		if ("machinery")
			sell_machinery(produce)
		if ("organs") //selling organs on the open market is illegal
			add_fine("organs", rand(10, 20))
			return

	sell_gas(produce)
	add_points_from_source(get_supply_value(value, sale), sale, TRUE)

/datum/controller/subsystem/supply/proc/sell_machinery(obj/machinery/machine)
	if (istype(machine, /obj/machinery/portable_atmospherics))
		sell_gas(machine)
	add_points_from_source(get_supply_value(get_value(machine), "machinery"), "machinery", TRUE)

/datum/controller/subsystem/supply/proc/sell_gas(obj/container)
	var/value = 0
	var/gas_mix = list()
	if (istype(container, /obj/machinery/portable_atmospherics))
		var/obj/machinery/portable_atmospherics/can = container
		gas_mix = can.air_contents.gas
	else if (istype(container, /obj/item/tank))
		var/obj/item/tank/tank = container
		gas_mix = tank.air_contents.gas
	else
		return
	for (var/chem in gas_mix)
		value += gas_data.price[chem] * gas_mix[chem] / 1000
	add_points_from_source(get_supply_value(value, "gas"), "gas", TRUE)

/datum/controller/subsystem/supply/proc/sell_liquid(obj/container)
	var/value = 0
	var/datum/reagents/reagent_datum = container.reagents
	if (!reagent_datum)
		return
	for (var/datum/reagent/chem in reagent_datum.reagent_list)
		value += chem.value * chem.volume
	add_points_from_source(get_supply_value(value, "liquid"), "liquid", TRUE)
	return value / GLOB.using_map.supply_price_multiplier //items include their reagents in their price, so they must be separated

/datum/controller/subsystem/supply/proc/get_clear_turfs()
	var/list/clear_turfs = list()

	for(var/area/subarea in shuttle.shuttle_area)
		for(var/turf/T in subarea)
			if(T.density)
				continue
			var/occupied = 0
			for(var/atom/A in T.contents)
				if(!A.simulated)
					continue
				occupied = 1
				break
			if(!occupied)
				clear_turfs += T

	return clear_turfs

//Buyin
/datum/controller/subsystem/supply/proc/buy()
	if(!length(shoppinglist))
		return

	var/list/clear_turfs = get_clear_turfs()

	for(var/S in shoppinglist)
		if(!length(clear_turfs))
			break
		var/turf/pickedloc = pick_n_take(clear_turfs)
		shoppinglist -= S
		donelist += S

		var/datum/supply_order/SO = S
		var/singleton/hierarchy/supply_pack/SP = SO.object

		var/obj/A = new SP.containertype(pickedloc)
		A.SetName("[SP.containername][SO.comment ? " ([SO.comment])":"" ]")
		//supply manifest generation begin

		var/obj/item/paper/manifest/slip
		if(!SP.contraband)
			var/info = list()
			info +="<h3>[GLOB.using_map.boss_name] Shipping Manifest</h3><hr><br>"
			info +="Order #[SO.ordernum]<br>"
			info +="Destination: [GLOB.using_map.station_name]<br>"
			info +="[length(shoppinglist)] PACKAGES IN THIS SHIPMENT<br>"
			info +="CONTENTS:<br><ul>"

			slip = new /obj/item/paper/manifest(A, jointext(info, null))
			slip.is_copy = FALSE

		//spawn the stuff, finish generating the manifest while you're at it
		if(SP.access)
			if(!islist(SP.access))
				A.req_access = list(SP.access)
			else if(islist(SP.access))
				var/list/L = SP.access // access var is a plain var, we need a list
				A.req_access = L.Copy()

		var/list/spawned = SP.spawn_contents(A)
		if(slip)
			for(var/atom/content in spawned)
				slip.info += "<li>[content.name]</li>" //add the item to the manifest
			slip.info += "</ul><br>CHECK CONTENTS AND STAMP BELOW THE LINE TO CONFIRM RECEIPT OF GOODS<hr>"

// Adds any given item to the supply shuttle
/datum/controller/subsystem/supply/proc/addAtom(atom/movable/A)
	var/list/clear_turfs = get_clear_turfs()
	if(!length(clear_turfs))
		return FALSE

	var/turf/pickedloc = pick(clear_turfs)

	A.forceMove(pickedloc)

	return TRUE

/datum/supply_order
	var/ordernum
	var/timestamp
	var/singleton/hierarchy/supply_pack/object = null
	var/orderedby = null
	var/comment = null
	var/reason = null
	var/orderedrank = null //used for supply console printing
