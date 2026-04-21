class_name EventDirector extends Node

# Drives timed, story-beat events independent of the wave spawner:
#  - Divine Shrines (every ~90s, rare Hidden Altar variant)
#  - Elite Portals at 10:00 and 20:00
#  - Final Boss at 30:00 → triggers Victory

signal elite_slain(pos: Vector2)
signal final_boss_slain(pos: Vector2)

@export_node_path("Node2D") var player_path: NodePath
@export var shrine_scene: PackedScene = preload("res://events/Shrine.tscn")
@export var hidden_altar_scene: PackedScene = preload("res://events/HiddenAltar.tscn")
@export var elite_portal_scene: PackedScene = preload("res://events/ElitePortal.tscn")
@export var altar_of_gods_scene: PackedScene = preload("res://events/AltarOfGods.tscn")
@export var weapon_chest_scene: PackedScene = preload("res://pickups/WeaponChest.tscn")
@export var cyclops_scene: PackedScene = preload("res://enemies/cyclops/Cyclops.tscn")
@export var cyclops_data: EnemyData = preload("res://enemies/cyclops/cyclops.tres")
@export var cyclops_boss_data: EnemyData = preload("res://enemies/cyclops/cyclops_boss.tres")

@export var shrine_interval_start: float = 45.0   # first shrine appears early so v1 feels alive
@export var shrine_interval: float = 90.0
@export var hidden_altar_chance: float = 0.15
@export var hidden_altar_chance_per_luck: float = 0.03
@export var random_altar_interval: float = 120.0
@export var random_altar_chance: float = 0.12

@export_group("Debug")
@export var debug_spawn_altar: bool = true
@export var debug_spawn_elite: bool = true
@export var debug_spawn_weapon_chest: bool = true

@export var elite_times: Array[float] = [600.0, 1200.0]  # 10:00, 20:00
@export var final_boss_time: float = 1800.0              # 30:00

@export var spawn_radius_min: float = 260.0
@export var spawn_radius_max: float = 420.0
@export var elite_spawn_radius: float = 480.0
@export var final_boss_spawn_radius: float = 300.0

var _player: Node2D
var _next_shrine_at: float = 0.0
var _next_altar_at: float = 0.0
var _elapsed: float = 0.0
var _elites_spawned: Array[bool] = []
var _final_boss_triggered: bool = false


func _ready() -> void:
	add_to_group("event_director")
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	_next_shrine_at = shrine_interval_start
	_next_altar_at = random_altar_interval
	_elites_spawned.resize(elite_times.size())
	for i in elite_times.size():
		_elites_spawned[i] = false
	if SaveGame.debug_mode:
		if debug_spawn_altar:
			call_deferred("_spawn_altar_of_gods")
		if debug_spawn_elite:
			call_deferred("_debug_spawn_elite_direct")
		if debug_spawn_weapon_chest:
			call_deferred("_debug_spawn_weapon_chest")


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _next_shrine_at:
		_spawn_shrine_or_altar()
		_next_shrine_at = _elapsed + shrine_interval
	if _elapsed >= _next_altar_at:
		_next_altar_at = _elapsed + random_altar_interval
		if randf() < random_altar_chance:
			_spawn_altar_of_gods()
	for i in elite_times.size():
		if not _elites_spawned[i] and _elapsed >= elite_times[i]:
			_elites_spawned[i] = true
			_spawn_elite()
	if not _final_boss_triggered and _elapsed >= final_boss_time:
		_final_boss_triggered = true
		_spawn_final_boss()


func _spawn_shrine_or_altar() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var spawn_pos: Vector2 = _player.global_position + _random_offset()
	var can_drop_altar := not SaveGame.remaining_locked_gods().is_empty()
	var luck := 0
	if _player.has_method("get_stats"):
		luck = int(_player.get_stats().luck)
	var chance: float = hidden_altar_chance + hidden_altar_chance_per_luck * float(luck)
	if can_drop_altar and randf() < chance:
		var altar: Node2D = hidden_altar_scene.instantiate()
		altar.global_position = spawn_pos
		get_tree().current_scene.add_child(altar)
		_ping_hud("A Hidden Altar appears!")
	else:
		var shrine: Node2D = shrine_scene.instantiate()
		shrine.global_position = spawn_pos
		get_tree().current_scene.add_child(shrine)
		_ping_hud("A Divine Shrine appears!")


func _random_offset() -> Vector2:
	var r: float = lerp(spawn_radius_min, spawn_radius_max, randf())
	var angle: float = randf() * TAU
	return Vector2.from_angle(angle) * r


func _ping_hud(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(text, 2.0)


func _spawn_elite() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var angle: float = randf() * TAU
	var pos: Vector2 = _player.global_position + Vector2.from_angle(angle) * elite_spawn_radius
	var portal: ElitePortal = elite_portal_scene.instantiate()
	portal.cyclops_scene = cyclops_scene
	portal.cyclops_data = cyclops_data
	portal.global_position = pos
	portal.elite_spawned.connect(_on_elite_spawned)
	get_tree().current_scene.add_child(portal)
	_ping_hud("A Cyclops approaches!")


func _on_elite_spawned(enemy: Cyclops) -> void:
	enemy.is_final_boss = false
	enemy.elite_slain.connect(_on_elite_slain)


func _spawn_altar_of_gods() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var altar: Node2D = altar_of_gods_scene.instantiate()
	altar.global_position = _player.global_position + _random_offset()
	get_tree().current_scene.add_child(altar)
	_ping_hud("An Altar of the Gods appears!")


func _debug_spawn_weapon_chest() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var chest: Node2D = weapon_chest_scene.instantiate()
	chest.global_position = _player.global_position + Vector2(-120.0, 0.0)
	get_tree().current_scene.add_child(chest)


func _debug_spawn_elite_direct() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var pos: Vector2 = _player.global_position + Vector2(200.0, 0.0)
	var wave_director := get_tree().get_first_node_in_group("wave_director")
	var hp_mult: float = 1.0
	var dmg_mult: float = 1.0
	if wave_director and wave_director.has_method("current_hp_multiplier"):
		hp_mult = wave_director.current_hp_multiplier()
		dmg_mult = wave_director.current_damage_multiplier()
	var enemy: Cyclops = cyclops_scene.instantiate()
	enemy.setup(cyclops_data, hp_mult, dmg_mult, _player)
	enemy.is_final_boss = false
	enemy.elite_slain.connect(_on_elite_slain)
	enemy.global_position = pos
	get_tree().current_scene.add_child(enemy)
	_ping_hud("DEBUG: Elite spawned.")


func _on_elite_slain(pos: Vector2) -> void:
	elite_slain.emit(pos)
	_ping_hud("The Cyclops has fallen.")


func _spawn_final_boss() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var wave_director := get_tree().get_first_node_in_group("wave_director")
	var hp_mult: float = 1.0
	var dmg_mult: float = 1.0
	if wave_director and wave_director.has_method("current_hp_multiplier"):
		hp_mult = wave_director.current_hp_multiplier()
		dmg_mult = wave_director.current_damage_multiplier()
	var angle: float = randf() * TAU
	var pos: Vector2 = _player.global_position + Vector2.from_angle(angle) * final_boss_spawn_radius
	var boss: Cyclops = cyclops_scene.instantiate()
	boss.setup(cyclops_boss_data, hp_mult, dmg_mult, _player)
	boss.is_final_boss = true
	boss.coins_on_death = 40
	boss.coin_value = 10
	boss.global_position = pos
	boss.final_boss_slain.connect(_on_final_boss_slain)
	get_tree().current_scene.add_child(boss)
	_ping_hud("The Elder Cyclops descends on Olympus!")


func _on_final_boss_slain(pos: Vector2) -> void:
	final_boss_slain.emit(pos)


# ── Public debug API (called by DebugPanel) ───────────────────────────────────

func spawn_altar_now() -> void:
	_spawn_altar_of_gods()


func spawn_chest_now() -> void:
	_debug_spawn_weapon_chest()


func spawn_elite_now() -> void:
	_debug_spawn_elite_direct()
