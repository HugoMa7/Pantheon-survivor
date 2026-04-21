class_name SpinningShield extends Weapon

@export var orbit_speed: float = 2.6          # radians/s at level 1 (projectile_speed field drives this)
@export var shield_radius: float = 12.0
@export var hit_cooldown_per_enemy: float = 0.35
@export var shield_color: Color = Color(0.85, 0.88, 1.0, 1.0)

var _angle: float = 0.0
var _hit_cooldowns: Dictionary = {}


func _process(delta: float) -> void:
	var rot_speed: float = orbit_speed
	if data:
		rot_speed = data.base_projectile_speed * (1.0 + (_player_stats.projectile_speed_mult if _player_stats else 0.0))
	_angle = fmod(_angle + rot_speed * delta, TAU)

	for key in _hit_cooldowns.keys():
		_hit_cooldowns[key] -= delta
		if _hit_cooldowns[key] <= 0.0:
			_hit_cooldowns.erase(key)

	_check_hits()
	queue_redraw()


func _orbit_positions() -> Array:
	var count := current_projectile_count()
	var radius := current_area() if current_area() > 0 else 60.0
	var positions: Array = []
	for i in count:
		var a := _angle + TAU * float(i) / float(count)
		positions.append(Vector2(cos(a), sin(a)) * radius)
	return positions


func _check_hits() -> void:
	var dmg := current_damage()
	var positions := _orbit_positions()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var id := e.get_instance_id()
		if _hit_cooldowns.has(id):
			continue
		for p in positions:
			if e.global_position.distance_to(global_position + p) <= shield_radius + 10.0:
				e.take_damage(dmg)
				_hit_cooldowns[id] = hit_cooldown_per_enemy
				break


func _draw() -> void:
	for p in _orbit_positions():
		draw_circle(p, shield_radius, shield_color)
		draw_arc(p, shield_radius - 1.5, 0.0, TAU, 24, Color(1, 1, 1, 0.7), 2.0)
