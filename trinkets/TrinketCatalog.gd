class_name TrinketCatalog extends RefCounted

# Static catalog of all v1 trinkets, keyed by id.

const TRINKETS: Dictionary = {
	"hermes_sandal": preload("res://trinkets/hermes_sandal.tres"),
	"thors_belt": preload("res://trinkets/thors_belt.tres"),
	"atlas_shoulder": preload("res://trinkets/atlas_shoulder.tres"),
	"ares_locket": preload("res://trinkets/ares_locket.tres"),
	"fortuna_coin": preload("res://trinkets/fortuna_coin.tres"),
	"hades_obol": preload("res://trinkets/hades_obol.tres"),
}


static func get_trinket(id: String) -> Trinket:
	if TRINKETS.has(id):
		return TRINKETS[id]
	return null


static func all_ids() -> Array:
	return TRINKETS.keys()


static func remaining_locked() -> Array:
	var out: Array = []
	for id in TRINKETS.keys():
		if not SaveGame.trinket_unlocked(id):
			out.append(id)
	return out
