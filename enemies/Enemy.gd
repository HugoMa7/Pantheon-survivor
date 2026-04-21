class_name Enemy extends CharacterBody2D

signal died(enemy: Enemy)

@export var data: EnemyData

var current_hp: float = 1.0
var hp_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var _target: Node2D
var _attack_cooldown_left: float = 0.0

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


func _physics_process(delta: float) -> void:
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
	current_hp -= amount
	if current_hp <= 0.0:
		died.emit(self)
		queue_free()
