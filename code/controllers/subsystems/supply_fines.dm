/obj/item/paper/fine
	name = "fine letter"
	var/destinations = list("Torch - Quartermaster's Office")
	var/subject
	var/origin = "NanoTrasen Logistics"

/obj/item/paper/fine/Initialize(mapload, text, title, list/metadata, datum/language/language)
	. = ..()


/obj/item/paper/fine/proc/update_fine(total = 1000)
	info = replacetext(info, "<time>", stationtime2text())
	info = replacetext(info, "<date>", stationdate2text())
	info = replacetext(info, "<total>", "[total]T")
	var/subcount = 0
	var/searchpoint = 0
	searchpoint = findtext_char(info, "<subtotal>")
	while (searchpoint > 0)
		info = replacetext_char(info, "<subtotal>", "<fill_ins>", searchpoint, searchpoint + 11)
		subcount += 1
		searchpoint = findtext_char(info, "<subtotal>")
	var/subtotal_list = list()
	var/max = total
	var/min = ceil(total / (subcount * 2))
	for (var/i = 1 to subcount - 1) //generate a sequence of numbers (within a certain range) that add up to the total
		var/current_gen = rand(min, max - (subcount - i ) * min)
		subtotal_list += round(current_gen)
		max -= current_gen
	subtotal_list += max
	subtotal_list = shuffle(subtotal_list)
	searchpoint = findtext_char(info, "<fill_ins>")
	var/sub_pos = 0
	while (searchpoint > 0)
		sub_pos += 1
		info = replacetext_char(info, "<fill_ins>", "[subtotal_list[sub_pos]]T", searchpoint, searchpoint + 11)
		searchpoint = findtext_char(info, "<fill_ins>")



/obj/item/paper/fine/carcass
	subject = "carcass"
	info = {"<tt><center><img src = bluentlogo.png></center><center><small>NanoTrasen Supply Depot 6EQUJ5</small></center><br>
<center><large><h2>NOTICE OF INFRACTION</h1></large></center><hr><hr><small><b>Date:</b> <date><br>
<b>Time:</b> <time></small>
<br><br>
<b>Recipient:</b> NEV Torch
<br><br>
<b>Violation:</b> Transportation of unsecured livestock via supply drone.
<br><br>
<b>Fine:</b>
<br><br>
<small>Drone Sanitation Fee - <subtotal>
<br>
Biohazard Decontamination Surcharge - <subtotal>
<br>
Mechanical Inspection Fee - <subtotal>
<br>
Auto Insurance Premium Copay - <subtotal>
<br>
Health Insurance Premium Copay - <subtotal>
<br>
Cost of Labor - <subtotal>
<br>
<b>Total:</b> <total>
<br><br>
This Fine has been automatically charged to your Supply account.
<br><br>
Have a nice day.</tt>
	"}

/obj/item/paper/fine/organs
	subject = "organs"
	info = {"
	"}

/obj/item/paper/fine/corpse
	subject = "corpse"
	destinations = list(
		"Torch - Quartermaster's Office",
		"Torch - Bridge"
	)
	info = {"<tt><center><bluelogo></center><center><small>NanoTrasen Supply Depot 6EQUJ5</small></center><br>
<center><large><h2>URGENT NOTICE</h1></large></center><hr><hr><small><b>Date:</b> <date><br>
<b>Time:</b> <time></small>
<br><br>
<b>Recipient:</b> NEV Torch
<br><br>
<b>Memo:</b> Be advised, human remains were found in a supply drone that had recently arrived from your vessel.
<br><br>
The NAP have been notified, but due to our remote location it will most likely take multible hours for investigators to arrive; until then we are unable to determine cause of death, time of death, or identity of the deceased.
<br><br>
The remains have been partially disfigured due to standard-operation depressurization of the drone's cabin, it is possible death occured during transit, but as stated above we are unable to confirm.
<br><br>
Attached below is a Fine for the relevant infraction.
<hr><br>
<b>Violation:</b> Unauthorized transportation of human remains via supply drone.
<br><br>
<b>Fine:</b>
<br><br>
<small>Drone Sanitation Fee - <subtotal>
<br>
Biohazard Decontamination Surcharge - <subtotal>
<br>
Mechanical Inspection Fee - <subtotal>
<br>
Cadaver Storage Fee - <subtotal>
<br>
Auto Insurance Premium Copay - <subtotal>
<br>
Health Insurance Premium Copay - <subtotal>
<br>
Life Insurance Premium Copay - <subtotal>
<br>
Delay of Business Operations Restitution Fee - <subtotal>
<br>
Cost of Labor - <subtotal>
<br>
<b>Total:</b> <total>
<br><br>
This Fine has been automatically charged to your Supply account.
<br><br>
Have a nice day.</tt>
	"}

/obj/item/paper/fine/organs
	subject = "organs"
	destinations = list(
		"Torch - Quartermaster's Office",
		"Torch -  Bridge"
	)
	info = {"<tt><center><bluelogo></center><center><small>NanoTrasen Supply Depot 6EQUJ5</small></center><br>
<center><large><h2>URGENT NOTICE</h1></large></center><hr><hr><small><b>Date:</b> <date><br>
<b>Time:</b> <time></small>
<br><br>
<b>Recipient:</b> NEV Torch
<br><br>
<b>Memo:</b> Be advised, human organs were found in a supply drone that had recently sourced from your vessel.
<br><br>
The NAP has been notified, but due to our remote location it will most likely take multiple hours for investigators to arrive; until then we are unable to determine their providence.
<br><br>
Attached below is a Fine for the relevant infraction.
<hr><br>
<b>Violation:</b> Unauthorized transportation of human viscera via supply drone.
<br><br>
<b>Fine:</b>
<br><br>
<small>Drone Sanitation Fee -
<br>
Biohazard Decontamination Surcharge -
<br>
Mechanical Inspection Fee -
<br>
Cadaver Storage Fee -
<br>
Mental Counseling Copay -
<br>
Auto Insurance Premium Copay -
<br>
Health Insurance Premium Copay -
<br>
Delay of Business Operations Restitution Fee -
<br>
Cost of Labor -
<br>
</small>

<b>Total:</b>
<br><br>
This Fine has been automatically charged to your Supply account.
<br><br>
Have a nice day.</tt>"
	}

/obj/item/paper/fine/artifact
	subject = "artifact"
	destinations = list(
		"Torch - Quartermaster's Office",
		"Torch - Bridge"
	)
	info = {"<tt><center><bluelogo></center><center><small>NanoTrasen Supply Depot 6EQUJ5</small></center><br>
<center><large><h2>NOTICE OF INFRACTION</h1></large></center><hr><hr><small><b>Date:</b> <date><br>
<b>Time:</b> <time></small><br>
<br><br>
<b>Recipient:</b> NEV Torch
<br><br>
<b>Violation:</b> Transportation of unsecured xenological materials via supply drone.
<br><br>
<b>Fine:</b>
<br><br>
<small>Drone Sanitation Fee -
<br>
Environmental Sterilization Surcharge -
<br>
Hazardous Materials Handling Fee -
<br>
Radiological Survey Fee -
<br>
Mechanical Inspection Fee -
<br>
Level-A Personal Protective Equipment Sanitation Fee -
<br>
Mental Counseling Copay -
<br>
Personnel Medical Exams Copay -
<br>
Auto Insurance Premium Copay -
<br>
Health Insurance Premium Copay -
<br>
Damage Deposit to Corporate Property -
<br>
Xenological Acquisitions Surcharge -
<br>
Delay of Business Operations Restitution Fee -
<br>
Cost of Labor -
<br>
<b>Total:</b> T15000
<br><br>
This Fine has been automatically charged to your Supply account.
<br><br>
Have a nice day.</tt>
	"}
