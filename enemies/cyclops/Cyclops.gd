class_name Cyclops extends Enemy

# Elite / boss enemy. Extends the base Enemy behavior with:
#  - optional ranged rock-throw (when data.is_ranged)
#  - guaranteed Relic Chest drop on death
#  - optional final-boss flag (triggers Victory signal)
#  - signals for Main to listen to (victory, elite_slain)

const ENEMY_PROJECTILE_SCENE := preload("res://enemies/EnemyProjectile.tscn")
const RELIC_CHEST_SCENE := preload("res://pickups/RelicChest.tscn")
const GOLD_COIN_SCENE := preload("res://pickups/GoldCoin.tscn")

signal final_boss_slain(pos: Vector2)
signal elite_slain(pos: Vector2)

@export var is_final_boss: bool = false
@export var coins_on_death: int = 20
@export var coin_value: int = 5

var _ranged_cd: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	var to_target: Vector2 = _target.global_position - global_position
	var dist: float = to_target.length()
	var dir: Vector2 = to_target.normalized() if dist > 0.01 else Vector2.ZERO

	# Ranged behavior: keep some stand-off distance and throw projectiles
	if data.is_ranged and data.attack_range > 0.0:
		_ranged_cd = max(0.0, _ranged_cd - delta)
		if dist > data.attack_range * 0.9:
			velocity = dir * data.base_speed
		elif dist < data.attack_range * 0.6:
			velocity = -dir * data.base_speed * 0.5
		else:
			velocity = Vector2.ZERO
		if _ranged_cd <= 0.0 and dist <= data.attack_range:
			_throw_rock(dir)
			_ranged_cd = data.attack_cooldown
	else:
		velocity = dir * data.base_speed

	move_and_slide()

	# Melee contact (still available even on the ranged boss for when the player closes in)
	_attack_cooldown_left = max(0.0, _attack_cooldown_left - delta)
	if _attack_cooldown_left <= 0.0 and hurt_area.overlaps_body(_target):
		_deal_contact_damage()


func _throw_rock(dir: Vector2) -> void:
	var proj: EnemyProjectile = ENEMY_PROJECTILE_SCENE.instantiate()
	var spd: float = data.projectile_speed if data.projectile_speed > 0.0 else 220.0
	proj.launch(global_position, dir, spd, data.base_damage * damage_multiplier)
	get_tree().current_scene.add_child(proj)


func take_damage(amount: float) -> void:
	current_hp -= amount
	if current_hp <= 0.0:
		_on_death()
		died.emit(self)
		queue_free()


func _on_death() -> void:
	# Drop a pile of gold coins so it's felt + visually satisfying
	for i in coins_on_death:
		var coin: GoldCoin = GOLD_COIN_SCENE.instantiate()
		coin.amount = coin_value
		var jitter := Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		coin.global_position = global_position + jitter
		get_tree().current_scene.add_child(coin)
	# Drop a Relic Chest
	var chest: RelicChest = RELIC_CHEST_SCENE.instantiate()
	chest.global_position = global_position
	get_tree().current_scene.add_child(chest)

	if is_final_boss:
		final_boss_slain.emit(global_position)
	else:
		elite_slain.emit(global_position)
