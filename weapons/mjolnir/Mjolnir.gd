class_name MjolnirWeapon extends Weapon

@export var hammer_color: Color = Color(0.95, 0.55, 0.25)
@export var hammer_radius: float = 14.0
@export var return_catch_dist: float = 18.0

var _cd_left: float = 0.4
var _hammers: Array = []

enum State { OUT, RETURN }


func _process(delta: float) -> void:
	_cd_left -= delta
	if _cd_left <= 0.0:
		_cd_left = current_cooldown()
		_throw()
		if should_phantom():
			_throw()
	_tick(delta)
	queue_redraw()


func _reset_cooldown() -> void:
	_cd_left = 0.0


func reduce_cooldown(amount: float) -> void:
	_cd_left = max(0.0, _cd_left - amount)


func _throw() -> void:
	var nearest := EnemyQuery.nearest(get_tree(), global_position, 600.0)
	var base_dir := Vector2.RIGHT
	if nearest:
		base_dir = (nearest.global_position - global_position).normalized()
	var count := current_projectile_count()
	var throw_dist := current_area()
	var is_crit := roll_crit()
	var dmg := apply_crit(current_damage()) if is_crit else current_damage()
	for i in count:
		var off := 0.0
		if count > 1:
			off = deg_to_rad(18.0) * (float(i) - float(count - 1) / 2.0)
		var d := base_dir.rotated(off)
		_hammers.append({
			"pos": global_position,
			"dir": d,
			"target": global_position + d * throw_dist,
			"state": State.OUT,
			"damage": dmg,
			"was_crit": is_crit,
			"hit_ids": {},
		})


func _tick(delta: float) -> void:
	var speed := current_projectile_speed()
	var remove: Array = []
	for h in _hammers:
		if h.state == State.OUT:
			h.pos += h.dir * speed * delta
			if h.pos.distance_to(h.target) < speed * delta:
				h.state = State.RETURN
		else:
			var to_player: Vector2 = global_position - h.pos
			if to_player.length() < return_catch_dist:
				remove.append(h)
				continue
			h.pos += to_player.normalized() * speed * delta

		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e):
				continue
			var id := e.get_instance_id()
			if h.hit_ids.has(id):
				continue
			if e.global_position.distance_to(h.pos) <= hammer_radius + 10.0:
				if e.has_method("take_damage"):
					e.take_damage(h.damage)
				apply_god_effects(e, h.damage, h.was_crit)
				h.hit_ids[id] = true

	for r in remove:
		_hammers.erase(r)


func _draw() -> void:
	for h in _hammers:
		var lp := to_local(h.pos)
		draw_circle(lp, hammer_radius, hammer_color)
		draw_arc(lp, hammer_radius - 1.0, 0.0, TAU, 24, Color(1, 1, 0.6, 0.8), 2.0)
