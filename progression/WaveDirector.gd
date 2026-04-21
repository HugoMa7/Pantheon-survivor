class_name WaveDirector extends Node

# Spawns enemies around the player. Scales count / HP / damage over time.
# Does NOT scale speed — different monster classes carry their own inherent speed.

@export var player_path: NodePath
@export var shade_scene: PackedScene
@export var shade_data: EnemyData
@export var xp_gem_scene: PackedScene
@export var gold_coin_scene: PackedScene = preload("res://pickups/GoldCoin.tscn")
@export var run_duration_sec: float = 1800.0   # 30 min run
@export var spawn_interval_start: float = 1.5
@export var spawn_interval_min: float = 0.15
@export var spawn_radius: float = 520.0
@export var max_alive: int = 400
@export var hp_mult_max: float = 20.0
@export var damage_mult_max: float = 4.0
@export var burst_count_max: int = 5

var elapsed: float = 0.0
var debug_density_mult: float = 1.0  # set by DebugPanel; >1 = denser

var _spawn_timer: float = 0.0
var _player: Node2D
var _alive_count: int = 0


func _ready() -> void:
	add_to_group("wave_director")
	if player_path.is_empty():
		push_warning("WaveDirector: player_path not set")
		return
	_player = get_node(player_path)


func current_hp_multiplier() -> float:
	return _current_hp_multiplier()


func current_damage_multiplier() -> float:
	return _current_damage_multiplier()


func spawn_shade_at(pos: Vector2) -> Enemy:
	if not shade_scene or not shade_data or not is_instance_valid(_player):
		return null
	var enemy: Enemy = shade_scene.instantiate()
	enemy.setup(shade_data, _current_hp_multiplier(), _current_damage_multiplier(), _player)
	enemy.global_position = pos
	enemy.died.connect(_on_enemy_died)
	_alive_count += 1
	get_tree().current_scene.add_child(enemy)
	return enemy


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	elapsed += delta
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _alive_count < max_alive:
		_spawn_timer = _current_spawn_interval()
		var burst := _current_burst_count()
		for i in burst:
			_spawn_shade()


func _progress() -> float:
	return clamp(elapsed / run_duration_sec, 0.0, 1.0)


func _current_spawn_interval() -> float:
	var base: float = lerp(spawn_interval_start, spawn_interval_min, _progress())
	return base / max(0.1, debug_density_mult)


func _current_burst_count() -> int:
	var base: float = lerp(1.0, float(burst_count_max), _progress())
	return max(1, int(round(base * debug_density_mult)))


func _current_hp_multiplier() -> float:
	return lerp(1.0, hp_mult_max, _progress())


func _current_damage_multiplier() -> float:
	return lerp(1.0, damage_mult_max, _progress())


func _spawn_shade() -> void:
	if not shade_scene or not shade_data or not is_instance_valid(_player):
		return
	var angle := randf() * TAU
	var pos: Vector2 = _player.global_position + Vector2(cos(angle), sin(angle)) * spawn_radius
	var enemy: Enemy = shade_scene.instantiate()
	enemy.setup(shade_data, _current_hp_multiplier(), _current_damage_multiplier(), _player)
	enemy.global_position = pos
	enemy.died.connect(_on_enemy_died)
	_alive_count += 1
	get_tree().current_scene.add_child(enemy)


func _on_enemy_died(enemy: Enemy) -> void:
	_alive_count -= 1
	if not enemy or not enemy.data:
		return
	if xp_gem_scene:
		var gem: XPGem = xp_gem_scene.instantiate()
		gem.xp_value = enemy.data.xp_value
		gem.global_position = enemy.global_position
		get_tree().current_scene.add_child(gem)
	_maybe_drop_gold(enemy)


func _maybe_drop_gold(enemy: Enemy) -> void:
	if gold_coin_scene == null or enemy == null or enemy.data == null:
		return
	if enemy.data.gold_drop_chance <= 0.0:
		return
	if randf() > enemy.data.gold_drop_chance:
		return
	var mn: int = max(1, enemy.data.gold_drop_min)
	var mx: int = max(mn, enemy.data.gold_drop_max)
	var amount: int = mn + randi() % (mx - mn + 1)
	var coin: GoldCoin = gold_coin_scene.instantiate()
	coin.amount = amount
	coin.global_position = enemy.global_position
	get_tree().current_scene.add_child(coin)
