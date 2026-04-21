class_name DivineFlame extends Weapon

@export var pulse_color: Color = Color(1.0, 0.55, 0.2, 0.7)

var _cd_left: float = 0.3
var _draw_radius: float = 0.0
var _draw_alpha: float = 0.0


func _process(delta: float) -> void:
	_cd_left -= delta
	if _cd_left <= 0.0:
		_cd_left = current_cooldown()
		_fire_pulse()
	if _draw_alpha > 0.0:
		queue_redraw()


func _fire_pulse() -> void:
	var radius := current_area()
	var damage := current_damage()

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

	_draw_radius = 10.0
	_draw_alpha = pulse_color.a
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "_draw_radius", radius, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_draw_alpha", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR)


func _draw() -> void:
	if _draw_alpha > 0.0:
		var c := pulse_color
		c.a = _draw_alpha
		draw_circle(Vector2.ZERO, _draw_radius, c)
		# inner brighter ring
		var inner := pulse_color
		inner.a = _draw_alpha * 0.4
		draw_circle(Vector2.ZERO, _draw_radius * 0.6, inner)
