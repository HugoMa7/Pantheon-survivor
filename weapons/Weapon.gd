class_name Weapon extends Node2D

const _PROJ_SCENE := preload("res://weapons/projectile/Projectile.tscn")
const _XP_SCENE   := preload("res://pickups/XPGem.tscn")

@export var data: WeaponData
var level: int = 1

var _player_stats: StatBlock
var _player: Node2D

# god_effects maps effect_id → level (1–3).  Repicking increments level up to 3.
var god_effects: Dictionary = {}

# Nine Lives charges (bastet_nine_lives) — read by Player._consume_nine_lives
var nine_lives_charges: int = 0

# Internal state used by specific effects.
var _hit_streak: int = 0           # zeus_overcharge
var _forced_crit: bool = false     # bastet_prowl
var _speed_boost_active: bool = false  # hermes_fleet
var _voltage_pending: bool = false # zeus_voltage
var _ballad_boost_active: bool = false # bragi_ballad
var _kill_count: int = 0           # anubis_ritual
var _iron_skin_stacks: int = 0     # thor_iron_skin
var _crit_counts: Dictionary = {}  # enemy instance_id → crit count (bastet_shred)


func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		if _player.has_method("get_stats"):
			_player_stats = _player.get_stats()


func level_up() -> void:
	if data:
		level = min(level + 1, data.max_level)


func current_damage() -> float:
	if not data:
		return 0.0
	var dmg := data.damage_at_level(level)
	if _player_stats:
		dmg *= (1.0 + _player_stats.damage_mult)
	if _voltage_pending:
		_voltage_pending = false
		var bonus: float = _get_val("zeus_voltage")
		dmg *= (1.0 + bonus)
	if _ballad_boost_active:
		dmg *= 1.25
	if _player_stats and is_instance_valid(_player) and "thor_berserker" in god_effects:
		var max_hp: float = _player.call("effective_max_hp") if _player.has_method("effective_max_hp") else 100.0
		var cur_hp_var = _player.get("current_hp")
		var cur_hp: float = float(cur_hp_var) if cur_hp_var != null else max_hp
		if cur_hp / max_hp < 0.40:
			dmg *= (1.0 + _get_val("thor_berserker"))
	return dmg


func current_cooldown() -> float:
	if not data:
		return 1.0
	var cd := data.cooldown_at_level(level)
	if _player_stats:
		cd = cd / (1.0 + _player_stats.attack_speed_mult)
	return max(0.08, cd)


func current_area() -> float:
	return data.area_at_level(level) if data else 0.0


func current_projectile_count() -> int:
	var n := data.projectile_count_at_level(level) if data else 1
	if _player_stats:
		n += _player_stats.projectile_count_bonus
	return max(1, n)


func current_projectile_speed() -> float:
	if not data:
		return 0.0
	var s := data.base_projectile_speed
	if _player_stats:
		s *= (1.0 + _player_stats.projectile_speed_mult)
	if "hermes_slipstream" in god_effects:
		s *= (1.0 + _get_val("hermes_slipstream"))
	return s


func roll_crit() -> bool:
	if _forced_crit:
		_forced_crit = false
		return true
	if not _player_stats:
		return false
	return randf() < _player_stats.crit_chance


func apply_crit(dmg: float) -> float:
	if not _player_stats:
		return dmg
	var crit_dmg := dmg * (1.0 + _player_stats.crit_damage_mult)
	if "bastet_huntress" in god_effects:
		crit_dmg *= (1.0 + _get_val("bastet_huntress"))
	return crit_dmg


func reduce_cooldown(_amount: float) -> void:
	pass  # overridden in subclasses


func _reset_cooldown() -> void:
	pass  # overridden in subclasses


# ── God effect dispatch ────────────────────────────────────────────────────────

func apply_god_effects(enemy: Node, dmg: float, was_crit: bool = false) -> void:
	if god_effects.is_empty() or not is_instance_valid(enemy):
		return
	var kill_pos: Vector2 = enemy.global_position
	var hp_val = enemy.get("current_hp")
	var was_kill: bool = hp_val != null and float(hp_val) <= 0.0
	var was_cursed: bool = enemy.has_method("is_cursed") and enemy.is_cursed()

	for effect: String in god_effects:
		match effect:
			"zeus_chain":        _fx_zeus_chain(enemy, dmg)
			"zeus_overcharge":   _fx_zeus_overcharge(enemy, dmg)
			"zeus_thundercrash": if was_kill: _fx_zeus_thundercrash(kill_pos)
			"zeus_static":       _fx_zeus_static(enemy)
			"zeus_voltage":      if was_kill: _voltage_pending = true
			"zeus_discharge":    if was_kill: _fx_zeus_discharge(kill_pos)
			"thor_knockback":    _fx_thor_knockback(enemy)
			"thor_stun":         _fx_thor_stun(enemy)
			"thor_cleave":       _fx_thor_cleave(enemy, dmg)
			"thor_berserker":    pass  # applied inside current_damage()
			"thor_quake":        if was_kill: _fx_thor_quake(kill_pos)
			"thor_iron_skin":    if was_kill: _fx_thor_iron_skin()
			"hermes_swift":      if was_kill: _fx_hermes_swift()
			"hermes_fleet":      if is_instance_valid(_player): _fx_hermes_fleet()
			"hermes_phantom":    pass  # handled per-weapon at fire time
			"hermes_dash":       if was_kill and is_instance_valid(_player): _fx_hermes_dash()
			"hermes_quickfingers": if was_kill: _fx_hermes_quickfingers()
			"hermes_slipstream": pass  # applied inside current_projectile_speed()
			"bragi_echo":        _fx_bragi_echo(enemy, dmg)
			"bragi_resonance":   if was_kill and is_instance_valid(_player): _fx_bragi_resonance()
			"bragi_saga":        if was_kill: _fx_bragi_saga(kill_pos)
			"bragi_chorus":      if was_kill: _fx_bragi_chorus(kill_pos)
			"bragi_ballad":      _fx_bragi_ballad()
			"bragi_verse":       _fx_bragi_verse(enemy.global_position)
			"bastet_bleed":      if was_crit: _fx_bastet_bleed(enemy)
			"bastet_prowl":      if was_crit: _forced_crit = true
			"bastet_mark":       _fx_bastet_mark(enemy)
			"bastet_huntress":   pass  # applied inside apply_crit()
			"bastet_shred":      if was_crit: _fx_bastet_shred(enemy)
			"bastet_nine_lives": pass  # static charges, handled in Player.take_damage
			"anubis_drain":      if is_instance_valid(_player): _fx_anubis_drain()
			"anubis_curse":      _fx_anubis_curse(enemy)
			"anubis_soul":       if was_kill: _fx_anubis_soul(kill_pos)
			"anubis_decay":      if was_kill and was_cursed: _fx_anubis_decay(kill_pos)
			"anubis_ritual":     if was_kill: _fx_anubis_ritual()
			"anubis_judgement":  if was_kill: _fx_anubis_judgement()


func should_phantom() -> bool:
	if "hermes_phantom" not in god_effects:
		return false
	return randf() < _get_val("hermes_phantom")


# ── Helpers ────────────────────────────────────────────────────────────────────

func _get_val(effect_id: String) -> float:
	return GodWeaponEffects.get_value(effect_id, god_effects.get(effect_id, 1))


func _get_radius(effect_id: String) -> float:
	# Some effects encode radius differently — reuse value as radius too
	# but for effects that have a radius stored separately we compute inline.
	return _get_val(effect_id)


func _all_weapons() -> Array:
	if not is_instance_valid(_player) or not _player.has_method("owned_weapons"):
		return []
	return _player.owned_weapons()


# ── Individual effect implementations ─────────────────────────────────────────

func _fx_zeus_chain(origin: Node, dmg: float) -> void:
	var chain_dmg := dmg * _get_val("zeus_chain")
	var targets := EnemyQuery.nearest_n(get_tree(), origin.global_position, 2, 150.0, [origin])
	for e in targets:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(chain_dmg)


func _fx_zeus_overcharge(enemy: Node, dmg: float) -> void:
	_hit_streak += 1
	if _hit_streak < 5:
		return
	_hit_streak = 0
	var hp_val = enemy.get("current_hp")
	if hp_val != null and float(hp_val) > 0 and enemy.has_method("take_damage"):
		enemy.take_damage(dmg * (_get_val("zeus_overcharge") - 1.0))


func _fx_zeus_thundercrash(kill_pos: Vector2) -> void:
	var lvl: int = god_effects.get("zeus_thundercrash", 1)
	var radii := [110.0, 140.0, 170.0]
	var radius: float = radii[clamp(lvl - 1, 0, 2)]
	var dmg: float = _get_val("zeus_thundercrash")
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(kill_pos) <= radius:
			if e.has_method("take_damage"):
				e.take_damage(dmg)


func _fx_zeus_static(enemy: Node) -> void:
	if is_instance_valid(enemy) and enemy.has_method("take_damage"):
		var hp_val = enemy.get("current_hp")
		if hp_val != null and float(hp_val) > 0:
			enemy.take_damage(_get_val("zeus_static"))


func _fx_zeus_discharge(kill_pos: Vector2) -> void:
	var lvl: int = god_effects.get("zeus_discharge", 1)
	var radii := [110.0, 140.0, 170.0]
	var radius: float = radii[clamp(lvl - 1, 0, 2)]
	var duration: float = _get_val("zeus_discharge")
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(kill_pos) <= radius:
			if e.has_method("apply_stun"):
				e.apply_stun(duration)


func _fx_thor_knockback(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var away: Vector2 = (enemy.global_position - global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	enemy.global_position += away * _get_val("thor_knockback")


func _fx_thor_stun(enemy: Node) -> void:
	if randf() < 0.25 and enemy.has_method("apply_stun"):
		enemy.apply_stun(_get_val("thor_stun"))


func _fx_thor_cleave(origin: Node, dmg: float) -> void:
	var splash := dmg * 0.5
	var radius: float = _get_val("thor_cleave")
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == origin or not is_instance_valid(e):
			continue
		if e.global_position.distance_to(origin.global_position) <= radius:
			if e.has_method("take_damage"):
				e.take_damage(splash)


func _fx_thor_quake(kill_pos: Vector2) -> void:
	var radius: float = _get_val("thor_quake")
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var away: Vector2 = e.global_position - kill_pos
		if away.length() <= radius:
			var dir: Vector2 = away.normalized() if away.length() > 0 else Vector2.RIGHT
			e.global_position += dir * 60.0


func _fx_thor_iron_skin() -> void:
	if not is_instance_valid(_player) or _iron_skin_stacks >= 10:
		return
	var gain: float = _get_val("thor_iron_skin")
	var add: float = min(gain, float(10 - _iron_skin_stacks))
	_iron_skin_stacks += int(add)
	if _player_stats:
		_player_stats.armor += add


func _fx_hermes_swift() -> void:
	_reset_cooldown()


func _fx_hermes_fleet() -> void:
	var boost: float = _get_val("hermes_fleet")
	if _speed_boost_active:
		return
	_speed_boost_active = true
	_player_stats.move_speed_mult += boost
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(_player):
			_player_stats.move_speed_mult -= boost
		_speed_boost_active = false
	)


func _fx_hermes_dash() -> void:
	if _player.has_method("grant_invincibility"):
		_player.grant_invincibility(_get_val("hermes_dash"))


func _fx_hermes_quickfingers() -> void:
	var reduction: float = _get_val("hermes_quickfingers")
	for w in _all_weapons():
		if w.has_method("reduce_cooldown"):
			w.reduce_cooldown(reduction)


func _fx_bragi_echo(enemy: Node, dmg: float) -> void:
	if randf() < 0.30 and is_instance_valid(enemy):
		var hp_val = enemy.get("current_hp")
		if hp_val != null and float(hp_val) > 0 and enemy.has_method("take_damage"):
			enemy.take_damage(dmg * _get_val("bragi_echo"))


func _fx_bragi_resonance() -> void:
	var bonus: float = _get_val("bragi_resonance")
	_player_stats.xp_mult += bonus
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if is_instance_valid(_player):
			_player_stats.xp_mult -= bonus
	)


func _fx_bragi_saga(kill_pos: Vector2) -> void:
	var lvl: int = god_effects.get("bragi_saga", 1)
	var counts := [2, 3, 4]
	var count: int = counts[clamp(lvl - 1, 0, 2)]
	var dmg: float = _get_val("bragi_saga")
	var targets := EnemyQuery.nearest_n(get_tree(), kill_pos, count, 600.0, [])
	for e in targets:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(dmg)


func _fx_bragi_chorus(kill_pos: Vector2) -> void:
	var dmg: float = _get_val("bragi_chorus")
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.global_position.distance_to(kill_pos) <= 100.0:
			if e.has_method("take_damage"):
				e.take_damage(dmg)


func _fx_bragi_ballad() -> void:
	if randf() >= _get_val("bragi_ballad") or _ballad_boost_active:
		return
	_ballad_boost_active = true
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		_ballad_boost_active = false
	)


func _fx_bragi_verse(spawn_pos: Vector2) -> void:
	if randf() >= _get_val("bragi_verse"):
		return
	var gem: Node2D = _XP_SCENE.instantiate()
	gem.global_position = spawn_pos
	get_tree().current_scene.add_child(gem)


func _fx_bastet_bleed(enemy: Node) -> void:
	if enemy.has_method("apply_bleed"):
		enemy.apply_bleed(_get_val("bastet_bleed"), 3.0)


func _fx_bastet_mark(enemy: Node) -> void:
	if enemy.has_method("apply_mark"):
		enemy.apply_mark(_get_val("bastet_mark"))
	elif enemy.has_method("add_mark_hit"):
		enemy.add_mark_hit()


func _fx_bastet_shred(enemy: Node) -> void:
	var id: int = enemy.get_instance_id()
	_crit_counts[id] = _crit_counts.get(id, 0) + 1
	var lvl: int = god_effects.get("bastet_shred", 1)
	var thresholds := [3, 2, 1]
	var threshold: int = thresholds[clamp(lvl - 1, 0, 2)]
	if _crit_counts[id] >= threshold:
		_crit_counts[id] = 0
		if enemy.has_method("apply_shred"):
			enemy.apply_shred(_get_val("bastet_shred"))


func _fx_anubis_drain() -> void:
	if _player.has_method("heal"):
		_player.heal(_get_val("anubis_drain"))


func _fx_anubis_curse(enemy: Node) -> void:
	if randf() < 0.20 and enemy.has_method("apply_curse"):
		var lvl: int = god_effects.get("anubis_curse", 1)
		var durations := [4.0, 5.0, 6.0]
		var dur: float = durations[clamp(lvl - 1, 0, 2)]
		enemy.apply_curse(dur, _get_val("anubis_curse"))


func _fx_anubis_soul(kill_pos: Vector2) -> void:
	var proj: Projectile = _PROJ_SCENE.instantiate()
	proj.modulate = Color(0.7, 0.3, 1.0)
	get_tree().current_scene.add_child(proj)
	proj.launch(kill_pos, Vector2.RIGHT, 420.0, _get_val("anubis_soul"), 3.0, 0, true)


func _fx_anubis_decay(kill_pos: Vector2) -> void:
	var count: int = int(_get_val("anubis_decay"))
	var targets := EnemyQuery.nearest_n(get_tree(), kill_pos, count, 200.0, [])
	for e in targets:
		if is_instance_valid(e) and e.has_method("apply_curse"):
			var lvl: int = god_effects.get("anubis_curse", 1)
			var durations := [4.0, 5.0, 6.0]
			e.apply_curse(durations[clamp(lvl - 1, 0, 2)], _get_val("anubis_curse"))


func _fx_anubis_ritual() -> void:
	_kill_count += 1
	var lvl: int = god_effects.get("anubis_ritual", 1)
	var thresholds := [15, 12, 9]
	var threshold: int = thresholds[clamp(lvl - 1, 0, 2)]
	if _kill_count >= threshold:
		_kill_count = 0
		if is_instance_valid(_player) and _player.has_method("heal"):
			_player.heal(_get_val("anubis_ritual"))


func _fx_anubis_judgement() -> void:
	if randf() < _get_val("anubis_judgement"):
		for w in _all_weapons():
			if w.has_method("reduce_cooldown"):
				w.reduce_cooldown(0.8)
