class_name Player extends CharacterBody2D

# Registry of all weapons known to v1.
const WEAPON_REGISTRY: Dictionary = {
	"divine_flame": {
		"scene": preload("res://weapons/flame/Flame.tscn"),
		"data": preload("res://weapons/flame/flame.tres"),
	},
	"hunters_bow": {
		"scene": preload("res://weapons/bow/Bow.tscn"),
		"data": preload("res://weapons/bow/bow.tres"),
	},
	"spinning_shield": {
		"scene": preload("res://weapons/shield/Shield.tscn"),
		"data": preload("res://weapons/shield/shield.tres"),
	},
	"zeus_bolt": {
		"scene": preload("res://weapons/bolt/Bolt.tscn"),
		"data": preload("res://weapons/bolt/bolt.tres"),
	},
	"mjolnir": {
		"scene": preload("res://weapons/mjolnir/Mjolnir.tscn"),
		"data": preload("res://weapons/mjolnir/mjolnir.tres"),
	},
	"scarab_swarm": {
		"scene": preload("res://weapons/scarabs/Scarabs.tscn"),
		"data": preload("res://weapons/scarabs/scarabs.tres"),
	},
}

signal died
signal health_changed(current: float, max_hp: float)
signal xp_changed(current_xp: int, xp_to_next: int, level: int)
signal leveled_up(new_level: int)
signal gold_changed(current: int)

@export var base_max_hp: float = 100.0
@export var base_move_speed: float = 220.0
@export var base_pickup_radius: float = 90.0
@export var max_weapon_slots: int = 3

var stats := StatBlock.new()
var current_hp: float
var level: int = 1
var current_xp: int = 0
var xp_to_next: int = 5
var gold: int = 0

@onready var weapons_node: Node2D = $Weapons


func _ready() -> void:
	add_to_group("player")
	max_weapon_slots = SaveGame.weapon_slots
	current_hp = effective_max_hp()
	xp_to_next = _xp_for_next_level(level)
	health_changed.emit(current_hp, effective_max_hp())
	xp_changed.emit(current_xp, xp_to_next, level)
	gold_changed.emit(gold)


func _physics_process(delta: float) -> void:
	var input_vec := InputController.get_move_vector()
	velocity = input_vec * effective_move_speed()
	move_and_slide()

	if stats.hp_regen > 0.0 and current_hp > 0.0 and current_hp < effective_max_hp():
		current_hp = min(effective_max_hp(), current_hp + stats.hp_regen * delta)
		health_changed.emit(current_hp, effective_max_hp())


func get_stats() -> StatBlock:
	return stats


func effective_max_hp() -> float:
	return base_max_hp + stats.max_hp_bonus


func effective_move_speed() -> float:
	return base_move_speed * (1.0 + stats.move_speed_mult)


func get_pickup_radius() -> float:
	return base_pickup_radius * (1.0 + stats.pickup_radius_mult)


func take_damage(amount: float) -> void:
	if current_hp <= 0.0:
		return
	var gross: float = amount * (1.0 + stats.damage_taken_mult)
	var net: float = max(0.0, gross - stats.armor)
	current_hp = max(0.0, current_hp - net)
	health_changed.emit(current_hp, effective_max_hp())
	if current_hp <= 0.0:
		died.emit()


func gain_xp(amount: int) -> void:
	var adj := int(round(float(amount) * (1.0 + stats.xp_mult)))
	current_xp += adj
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		xp_to_next = _xp_for_next_level(level)
		leveled_up.emit(level)
	xp_changed.emit(current_xp, xp_to_next, level)


func gain_gold(amount: int) -> void:
	gold += int(round(float(amount) * (1.0 + stats.gold_mult)))
	gold_changed.emit(gold)


func _xp_for_next_level(next_level: int) -> int:
	return int(round(5.0 * pow(float(next_level), 1.35)))


# --- Weapons ---

func owned_weapons() -> Array:
	var ws: Array = []
	if weapons_node:
		for child in weapons_node.get_children():
			if child is Weapon:
				ws.append(child)
	return ws


func slots_used() -> int:
	return owned_weapons().size()


func slots_free() -> int:
	return max(0, max_weapon_slots - slots_used())


func available_unowned_weapons() -> Array:
	var owned_ids: Dictionary = {}
	for w in owned_weapons():
		if w.data:
			owned_ids[w.data.id] = true
	var result: Array = []
	for id in WEAPON_REGISTRY.keys():
		if owned_ids.has(id):
			continue
		var wd: WeaponData = WEAPON_REGISTRY[id].data
		if wd.required_god_id != "" and not SaveGame.god_unlocked(wd.required_god_id):
			continue
		result.append(wd)
	return result


func add_weapon(weapon_id: String) -> Weapon:
	if slots_free() <= 0 or not WEAPON_REGISTRY.has(weapon_id):
		return null
	var scene: PackedScene = WEAPON_REGISTRY[weapon_id].scene
	var w: Weapon = scene.instantiate()
	weapons_node.add_child(w)
	return w


func upgrade_weapon(weapon_id: String) -> bool:
	for w in owned_weapons():
		if w.data and w.data.id == weapon_id:
			w.level_up()
			return true
	return false


# --- Card application ---

func apply_card(card: UpgradeCard) -> void:
	match card.type:
		UpgradeCard.Type.WEAPON_NEW:
			add_weapon(card.target_id)
		UpgradeCard.Type.WEAPON_UPGRADE:
			upgrade_weapon(card.target_id)
		UpgradeCard.Type.STAT:
			_apply_stat(card.target_id, card.value)
		UpgradeCard.Type.BLESSING:
			_apply_blessing(card.target_id, card.value)
	health_changed.emit(current_hp, effective_max_hp())


func _apply_stat(stat_id: String, value: float) -> void:
	match stat_id:
		"max_hp":
			stats.max_hp_bonus += value
			current_hp += value
		"move_speed":
			stats.move_speed_mult += value
		"damage":
			stats.damage_mult += value
		"attack_speed":
			stats.attack_speed_mult += value
		"pickup_radius":
			stats.pickup_radius_mult += value
		"armor":
			stats.armor += value
		"hp_regen":
			stats.hp_regen += value
		"crit_chance":
			stats.crit_chance += value
		"crit_damage":
			stats.crit_damage_mult += value
		"projectile_count":
			stats.projectile_count_bonus += int(value)
		"projectile_speed":
			stats.projectile_speed_mult += value
		"luck":
			stats.luck += int(value)


func _apply_blessing(key: String, value: float) -> void:
	match key:
		"lifesteal": stats.lifesteal += value
		"thorns": stats.thorns += value
		"xp_mult": stats.xp_mult += value
		"gold_mult": stats.gold_mult += value
		"damage_taken": stats.damage_taken_mult += value


func apply_blessing_resource(b: Blessing) -> void:
	if b == null:
		return
	if b.is_blessing_effect:
		_apply_blessing(b.stat_id, b.value)
	else:
		_apply_stat(b.stat_id, b.value)
	health_changed.emit(current_hp, effective_max_hp())


func apply_trinket(t: Trinket) -> void:
	if t == null:
		return
	for eff in t.effects:
		var stat_id: String = str(eff.get("stat_id", ""))
		var value: float = float(eff.get("value", 0.0))
		var is_blessing: bool = bool(eff.get("is_blessing", false))
		if stat_id == "":
			continue
		if is_blessing:
			_apply_blessing(stat_id, value)
		else:
			_apply_stat(stat_id, value)
	current_hp = min(current_hp, effective_max_hp())
	health_changed.emit(current_hp, effective_max_hp())
