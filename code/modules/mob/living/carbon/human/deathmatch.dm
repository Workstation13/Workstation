/singleton/hierarchy/outfit/deathmatch
	name = "Test Subject - Default"
	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/jackboots
	glasses = /obj/item/clothing/glasses/sunglasses
	suit = /obj/item/clothing/suit/armor/pcarrier/medium
	back = /obj/item/storage/backpack/satchel/grey
	belt = /obj/item/storage/belt/holster/security/tactical
	suit_store = /obj/item/gun/projectile/revolver/holdout
	gloves = /obj/item/clothing/gloves/thick
	l_pocket = /obj/item/ammo_magazine/speedloader/small
	r_pocket = /obj/item/material/knife/combat
	id_slot = slot_wear_id
	id_types = list(/obj/item/card/id/all_access)
	id_pda_assignment = "Test Subject"
	backpack_contents = list(/obj/item/storage/box/survival, /obj/item/ammo_magazine/speedloader/small)

/singleton/hierarchy/outfit/deathmatch/gopnik
	name = "Gopnik"
	uniform = /obj/item/clothing/under/casual_pants/track
	head = /obj/item/clothing/mask/bandana/skull
	shoes = /obj/item/clothing/shoes/athletic

/singleton/hierarchy/outfit/deathmatch/sindy
	name = "Syndie"
	head = /obj/item/clothing/head/chefhat
	uniform = /obj/item/clothing/under/color/grey/sindy
	shoes = /obj/item/clothing/shoes/athletic

/obj/item/clothing/under/color/grey/sindy
	accessories = list(/obj/item/clothing/accessory/toggleable/hawaii/red)

/singleton/hierarchy/outfit/deathmatch/clown
	name = "Evil Clown"
	uniform = /obj/item/clothing/under/color/rainbow
	mask = /obj/item/clothing/mask/gas/clown_hat
	back = /obj/item/storage/backpack/clown

/singleton/hierarchy/outfit/deathmatch/luddite
	name = "Luddite"
	head = /obj/item/clothing/head/culthood
	uniform = /obj/item/clothing/under/color/red
	shoes = /obj/item/clothing/shoes/sandal

/singleton/hierarchy/outfit/deathmatch/agent
	name = "Secret Agent"
	uniform = /obj/item/clothing/under/suit_jacket
	shoes = /obj/item/clothing/shoes/dress

/singleton/hierarchy/outfit/deathmatch/tactical
	name = "Tacticool Operator"
	uniform = /obj/item/clothing/under/tactical
	mask = /obj/item/clothing/mask/balaclava

/singleton/hierarchy/outfit/deathmatch/cowboy
	name = "Cowboy"
	uniform = /obj/item/clothing/under/frontier
	head = /obj/item/clothing/head/cowboy_hat
	mask = /obj/item/clothing/mask/bandana/red
	shoes = /obj/item/clothing/shoes/leather

/singleton/hierarchy/outfit/deathmatch/soviet
	name = "Soviet Soldier"
	uniform = /obj/item/clothing/under/soviet
	shoes = /obj/item/clothing/shoes/combat
	head = /obj/item/clothing/head/ushanka

/singleton/hierarchy/outfit/deathmatch/pirate
	name = "Pirate"
	uniform = /obj/item/clothing/under/pirate
	shoes = /obj/item/clothing/shoes/sandal
	head = /obj/item/clothing/mask/bandana/red


/mob/living/carbon/human/contestant/Initialize(mapload, new_species)
	. = ..()
	return INITIALIZE_HINT_LATELOAD

/mob/living/carbon/human/contestant/LateInitialize(mapload)
	var/singleton/hierarchy/outfit/deathmatch/deathmatch_outfits = list()
	for (var/singleton/hierarchy/outfit/deathmatch/death_outfit in outfits())
		deathmatch_outfits += death_outfit
	var/singleton/hierarchy/outfit/outfit = pick(deathmatch_outfits)
	outfit.equip(src)
	randomize_skin_tone()
	randomize_hair_color()
	facial_hair_color = head_hair_color
	randomize_eye_color()
	randomize_hair_style()
	randomize_facial_hair_style()
	var/datum/language/language = new /datum/language/human
	fully_replace_character_name(language.get_random_name(gender))
