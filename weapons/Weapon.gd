class_name Weapon extends Node2D

@export var data: WeaponData
var level: int = 1

var _player_stats: StatBlock


func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0].has_method("get_stats"):
		_player_stats = players[0].get_stats()


func level_up() -> void:
	if data:
		level = min(level + 1, data.max_level)


func current_damage() -> float:
	if not data:
		return 0.0
	var dmg := data.damage_at_level(level)
	if _player_stats:
		dmg *= (1.0 + _player_stats.damage_mult)
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
	return s


func roll_crit() -> bool:
	if not _player_stats:
		return false
	return randf() < _player_stats.crit_chance


func apply_crit(dmg: float) -> float:
	if not _player_stats:
		return dmg
	return dmg * (1.0 + _player_stats.crit_damage_mult)
