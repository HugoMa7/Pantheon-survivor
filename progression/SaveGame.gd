extends Node

# Persistent save — autoload singleton.
# Tracks meta-progression across runs.

const SAVE_PATH := "user://save.cfg"

# Default starting state: three minor gods pre-unlocked, nothing else.
const DEFAULT_UNLOCKED_GODS: Array[String] = ["hermes", "bragi", "bastet"]

var unlocked_gods: Array = []
var unlocked_trinkets: Array = []
var gold: int = 0
var weapon_slots: int = 3
var selected_god: String = ""
var selected_trinket: String = ""
var selected_weapon: String = "divine_flame"
var interacted_gods: Array = []

# Session-only (never persisted) — toggled on pre-run screen.
var debug_mode: bool = false


func _ready() -> void:
	load_save()


func load_save() -> void:
	var f := ConfigFile.new()
	var err := f.load(SAVE_PATH)
	if err != OK:
		unlocked_gods = DEFAULT_UNLOCKED_GODS.duplicate()
		unlocked_trinkets = []
		gold = 0
		weapon_slots = 3
		selected_god = "hermes"
		selected_trinket = ""
		selected_weapon = "divine_flame"
		save_save()
		return
	unlocked_gods = f.get_value("save", "unlocked_gods", DEFAULT_UNLOCKED_GODS.duplicate())
	unlocked_trinkets = f.get_value("save", "unlocked_trinkets", [])
	gold = int(f.get_value("save", "gold", 0))
	weapon_slots = int(f.get_value("save", "weapon_slots", 3))
	selected_god = str(f.get_value("save", "selected_god", "hermes"))
	selected_trinket = str(f.get_value("save", "selected_trinket", ""))
	selected_weapon = str(f.get_value("save", "selected_weapon", "divine_flame"))
	interacted_gods = f.get_value("save", "interacted_gods", [])


func save_save() -> void:
	var f := ConfigFile.new()
	f.set_value("save", "unlocked_gods", unlocked_gods)
	f.set_value("save", "unlocked_trinkets", unlocked_trinkets)
	f.set_value("save", "gold", gold)
	f.set_value("save", "weapon_slots", weapon_slots)
	f.set_value("save", "selected_god", selected_god)
	f.set_value("save", "selected_trinket", selected_trinket)
	f.set_value("save", "selected_weapon", selected_weapon)
	f.set_value("save", "interacted_gods", interacted_gods)
	f.save(SAVE_PATH)


func record_god_interaction(god_id: String) -> void:
	if god_id not in interacted_gods:
		interacted_gods.append(god_id)
	unlock_god(god_id)
	save_save()


func god_unlocked(id: String) -> bool:
	return id in unlocked_gods


func unlock_god(id: String) -> bool:
	if id in unlocked_gods:
		return false
	unlocked_gods.append(id)
	save_save()
	return true


func trinket_unlocked(id: String) -> bool:
	return id in unlocked_trinkets


func unlock_trinket(id: String) -> bool:
	if id in unlocked_trinkets:
		return false
	unlocked_trinkets.append(id)
	save_save()
	return true


func add_gold(amount: int) -> void:
	gold += amount
	save_save()


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	save_save()
	return true


func remaining_locked_gods() -> Array:
	var all := ["zeus", "thor", "anubis"]
	var result: Array = []
	for g in all:
		if not g in unlocked_gods:
			result.append(g)
	return result


# --- Hub: weapon slot upgrade ladder ---

const MAX_WEAPON_SLOTS: int = 6

func next_slot_cost() -> int:
	if weapon_slots >= MAX_WEAPON_SLOTS:
		return -1
	# 3 -> 4: 100, 4 -> 5: 200, 5 -> 6: 400
	match weapon_slots:
		3: return 100
		4: return 200
		5: return 400
	return 999999

func buy_next_weapon_slot() -> bool:
	var cost := next_slot_cost()
	if cost <= 0 or gold < cost or weapon_slots >= MAX_WEAPON_SLOTS:
		return false
	gold -= cost
	weapon_slots += 1
	save_save()
	return true
