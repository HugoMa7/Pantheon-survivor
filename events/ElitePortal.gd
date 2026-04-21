class_name ElitePortal extends Node2D

# Portal marker that pulses at a map location, then spawns a Cyclops
# and a Shade escort after a short countdown.

signal elite_spawned(enemy: Cyclops)

@export var cyclops_scene: PackedScene = preload("res://enemies/cyclops/Cyclops.tscn")
@export var cyclops_data: EnemyData = preload("res://enemies/cyclops/cyclops.tres")
@export var countdown: float = 3.0
@export var escort_count: int = 5
@export var portal_color: Color = Color(0.7, 0.25, 0.9, 1)
@export var radius: float = 48.0

var _time_left: float
var _spawned: bool = false


func _ready() -> void:
	_time_left = countdown
	set_process(true)


func _process(delta: float) -> void:
	if _spawned:
		return
	_time_left = max(0.0, _time_left - delta)
	queue_redraw()
	if _time_left <= 0.0:
		_spawn()


func _draw() -> void:
	var t: float = 1.0 - (_time_left / max(0.001, countdown))
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
	draw_circle(Vector2.ZERO, radius * pulse, portal_color * Color(1, 1, 1, 0.35))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, portal_color, 3.0)
	draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU * t, 48, Color.WHITE, 2.0)


func _spawn() -> void:
	_spawned = true
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		queue_free()
		return
	var wave_director := get_tree().get_first_node_in_group("wave_director")
	var hp_mult: float = 1.0
	var dmg_mult: float = 1.0
	if wave_director and wave_director.has_method("current_hp_multiplier"):
		hp_mult = wave_director.current_hp_multiplier()
		dmg_mult = wave_director.current_damage_multiplier()

	var cyclops: Cyclops = cyclops_scene.instantiate()
	cyclops.setup(cyclops_data, hp_mult, dmg_mult, player)
	cyclops.global_position = global_position
	get_tree().current_scene.add_child(cyclops)
	elite_spawned.emit(cyclops)

	# Shade escort
	if wave_director and wave_director.has_method("spawn_shade_at"):
		for i in escort_count:
			var angle: float = TAU * float(i) / float(escort_count)
			var offset: Vector2 = Vector2.from_angle(angle) * (radius + 20.0)
			wave_director.spawn_shade_at(global_position + offset)

	queue_free()
