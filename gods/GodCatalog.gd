class_name GodCatalog extends RefCounted

# Static lookup of god id → GodData resource.
# Single source of truth for the v1 god roster.

const GODS: Dictionary = {
	"hermes": preload("res://gods/hermes.tres"),
	"bragi": preload("res://gods/bragi.tres"),
	"bastet": preload("res://gods/bastet.tres"),
	"zeus": preload("res://gods/zeus.tres"),
	"thor": preload("res://gods/thor.tres"),
	"anubis": preload("res://gods/anubis.tres"),
}


static func get_god(id: String) -> GodData:
	if GODS.has(id):
		return GODS[id]
	return null


static func all_ids() -> Array:
	return GODS.keys()
