//Armor that degrades with taken damage
/datum/extension/armor/ablative
	var/list/max_armor_values
	var/armor_degradation_coef //How fast armor degrades with blocked damage, with armor value reduced by [coef * damage taken]
	var/list/last_reported_damage  //for wearer feedback

/datum/extension/armor/ablative/New(atom/movable/holder, list/armor, _armor_degradation_speed)
	..()
	max_armor_values = armor_values.Copy()
	if(_armor_degradation_speed)
		armor_degradation_coef = _armor_degradation_speed

/datum/extension/armor/ablative/on_blocking(damage, damage_type, damage_flags, armor_pen, blocked)
	if(!(damage_type == DAMAGE_BRUTE || damage_type == DAMAGE_BURN))
		return
	if(armor_degradation_coef)
		var/key = get_armor_key(damage_type, damage_flags)
		var/damage_blocked = round(damage * blocked)
		if(damage_blocked)
			var/new_armor = max(0, get_value(key) - armor_degradation_coef * (damage_blocked + armor_pen))
			set_value(key, new_armor)
			var/mob/M = get_holder_of_type(holder, /mob)
			if(istype(M))
				var/list/visible = get_visible_damage()
				for(var/k in visible)
					if(LAZYACCESS(last_reported_damage, k) != visible[k])
						LAZYSET(last_reported_damage, k, visible[k])
						to_chat(M, SPAN_WARNING("The [k] armor on your [holder] has [visible[k]] damage now!"))

/datum/extension/armor/ablative/proc/get_damage()
	for(var/key in armor_values)
		var/damage = max_armor_values[key] - armor_values[key]
		if(damage > 0)
			LAZYSET(., key, damage)

/datum/extension/armor/ablative/proc/get_visible_damage()
	var/list/damages = get_damage()
	if(!LAZYLEN(damages))
		return
	var/result = list()
	for(var/key in damages)
		switch(round(100 * damages[key]/max_armor_values[key]))
			if(5 to 10)
				result[key] = "trivial"
			if(11 to 25)
				result[key] = "minor"
			if(26 to 50)
				result[key] = "moderate"
			if(51 to 99)
				result[key] = "severe"
			if(100)
				result[key] = "catastrophic"
	return result

/datum/extension/armor/ablative/rig
	var/sealed = FALSE

/datum/extension/armor/ablative/rig/get_value(key)
	if(key == "bio" && sealed)
		return 100
	return ..()
