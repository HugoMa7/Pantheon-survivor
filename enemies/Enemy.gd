class_name Enemy extends CharacterBody2D

signal died(enemy: Enemy)

@export var data: EnemyData

var current_hp: float = 1.0
var hp_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var _target: Node2D
var _attack_cooldown_left: float = 0.0

# Status effects
var _stun_timer: float = 0.0
var _bleed_timer: float = 0.0
var _bleed_dps: float = 0.0
var _curse_timer: float = 0.0
var _curse_bonus: float = 0.30  # set by apply_curse
var _mark_hits: int = 0
var _mark_bonus: float = 0.40   # set by apply_mark
var _shred_mult: float = 0.0    # bonus damage taken from bastet_shred

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurt_area: Area2D = $HurtBox


func setup(enemy_data: EnemyData, hp_mult: float, dmg_mult: float, target: Node2D) -> void:
	data = enemy_data
	hp_multiplier = hp_mult
	damage_multiplier = dmg_mult
	_target = target
	current_hp = enemy_data.base_hp * hp_mult


func _ready() -> void:
	add_to_group("enemies")
	if data:
		_apply_visual()
	hurt_area.body_entered.connect(_on_body_entered)


func _apply_visual() -> void:
	if data.sprite:
		sprite.texture = data.sprite
		sprite.modulate = Color.WHITE
	else:
		sprite.modulate = data.color
	scale = Vector2.ONE * data.size


func _process(delta: float) -> void:
	if _bleed_timer > 0.0:
		_bleed_timer -= delta
		current_hp -= _bleed_dps * delta
		if current_hp <= 0.0:
			died.emit(self)
			queue_free()
			return
	if _curse_timer > 0.0:
		_curse_timer -= delta


func _physics_process(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(_target):
		return
	var dir := (_target.global_position - global_position).normalized()
	velocity = dir * data.base_speed
	move_and_slide()

	_attack_cooldown_left = max(0.0, _attack_cooldown_left - delta)
	if _attack_cooldown_left <= 0.0 and hurt_area.overlaps_body(_target):
		_deal_contact_damage()


func _on_body_entered(body: Node2D) -> void:
	if body == _target and _attack_cooldown_left <= 0.0:
		_deal_contact_damage()


func _deal_contact_damage() -> void:
	if _target and _target.has_method("take_damage"):
		_target.take_damage(data.base_damage * damage_multiplier)
	_attack_cooldown_left = data.attack_cooldown


func take_damage(amount: float) -> void:
	if current_hp <= 0.0:
		return
	var actual := amount
	if _curse_timer > 0.0:
		actual *= (1.0 + _curse_bonus)
	if _mark_hits >= 3:
		actual *= (1.0 + _mark_bonus)
	if _shred_mult > 0.0:
		actual *= (1.0 + _shred_mult)
	current_hp -= actual
	if current_hp <= 0.0:
		died.emit(self)
		queue_free()


func is_cursed() -> bool:
	return _curse_timer > 0.0


# ── Status effect appliers ────────────────────────────────────────────────────

func apply_stun(duration: float) -> void:
	_stun_timer = max(_stun_timer, duration)


func apply_bleed(dps: float, duration: float) -> void:
	_bleed_dps = max(_bleed_dps, dps)
	_bleed_timer = max(_bleed_timer, duration)


func apply_curse(duration: float, bonus: float = 0.30) -> void:
	_curse_timer = max(_curse_timer, duration)
	_curse_bonus = max(_curse_bonus, bonus)


func apply_mark(bonus: float) -> void:
	_mark_hits += 1
	_mark_bonus = max(_mark_bonus, bonus)


func apply_shred(bonus: float) -> void:
	_shred_mult = max(_shred_mult, bonus)


func add_mark_hit() -> void:
	apply_mark(0.40)
