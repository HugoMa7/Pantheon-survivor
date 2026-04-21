class_name ZeusBolt extends Weapon

@export var bolt_color: Color = Color(0.65, 0.85, 1.0, 1.0)
@export var chain_damage_mult: float = 0.75
@export var search_range: float = 700.0
@export var segment_lifetime: float = 0.15

var _cd_left: float = 0.5
var _segments: Array = []


func _process(delta: float) -> void:
	_cd_left -= delta
	if _cd_left <= 0.0:
		_cd_left = current_cooldown()
		_strike()
		if should_phantom():
			_strike()

	if not _segments.is_empty():
		var alive: Array = []
		for s in _segments:
			s.time_left -= delta
			if s.time_left > 0.0:
				alive.append(s)
		_segments = alive
		queue_redraw()


func _reset_cooldown() -> void:
	_cd_left = 0.0


func reduce_cooldown(amount: float) -> void:
	_cd_left = max(0.0, _cd_left - amount)


func _strike() -> void:
	var first := EnemyQuery.nearest(get_tree(), global_position, search_range)
	if not first:
		return
	var chains := current_projectile_count()
	var base_dmg := current_damage()
	var hit: Array = []
	var from_pos := global_position
	var cur: Node2D = first
	for i in chains:
		if not is_instance_valid(cur):
			break
		var is_crit := roll_crit()
		var dmg := apply_crit(base_dmg) if is_crit else base_dmg
		if cur.has_method("take_damage"):
			cur.take_damage(dmg)
		apply_god_effects(cur, dmg, is_crit)
		_segments.append({"a": from_pos, "b": cur.global_position, "time_left": segment_lifetime})
		hit.append(cur)
		from_pos = cur.global_position
		var next := EnemyQuery.nearest_n(get_tree(), cur.global_position, 1, current_area(), hit)
		if next.is_empty():
			break
		cur = next[0]
		base_dmg *= chain_damage_mult
	queue_redraw()


func _draw() -> void:
	for s in _segments:
		var alpha: float = clamp(float(s.time_left) / segment_lifetime, 0.0, 1.0)
		var c: Color = bolt_color
		c.a = alpha
		draw_line(to_local(s.a), to_local(s.b), c, 3.0)
		var core: Color = Color(1, 1, 1, alpha * 0.8)
		draw_line(to_local(s.a), to_local(s.b), core, 1.0)
