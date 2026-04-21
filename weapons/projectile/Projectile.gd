class_name Projectile extends Area2D

@export var speed: float = 400.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
@export var pierce: int = 0
@export var homing: bool = false
@export var turn_rate: float = 7.0

var was_crit: bool = false
var on_hit_extra: Callable = Callable()

var _dir: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0
var _pierce_left: int
var _hit_ids: Dictionary = {}
var _target: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(from: Vector2, dir: Vector2, spd: float, dmg: float, lt: float = 3.0, pr: int = 0, home: bool = false) -> void:
	global_position = from
	_dir = dir.normalized() if dir.length_squared() > 0.0 else Vector2.RIGHT
	speed = spd
	damage = dmg
	lifetime = lt
	pierce = pr
	_pierce_left = pr
	homing = home
	rotation = _dir.angle()


func _physics_process(delta: float) -> void:
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()
		return

	if homing:
		if not is_instance_valid(_target):
			_target = EnemyQuery.nearest(get_tree(), global_position)
		if is_instance_valid(_target):
			var target_angle := (_target.global_position - global_position).angle()
			var current_angle := _dir.angle()
			var new_angle := rotate_toward(current_angle, target_angle, turn_rate * delta)
			_dir = Vector2.from_angle(new_angle)
			rotation = new_angle

	global_position += _dir * speed * delta


func _on_body_entered(body: Node) -> void:
	var id := body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if on_hit_extra.is_valid():
			on_hit_extra.call(body, damage, was_crit)
	if _pierce_left > 0:
		_pierce_left -= 1
	else:
		queue_free()
