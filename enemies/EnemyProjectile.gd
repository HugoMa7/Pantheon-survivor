class_name EnemyProjectile extends Area2D

# Simple linear enemy projectile (e.g. Cyclops Boss's rock).
# Uses collision layer 32 = enemy_projectile, masks player (layer 2).

@export var speed: float = 220.0
@export var damage: float = 10.0
@export var lifetime: float = 4.0
@export var radius: float = 8.0
@export var projectile_color: Color = Color(0.6, 0.5, 0.4)

var _dir: Vector2 = Vector2.RIGHT
var _age: float = 0.0


func _ready() -> void:
	collision_layer = 32  # enemy_projectile
	collision_mask = 2    # player
	body_entered.connect(_on_body_entered)
	if not has_node("Shape"):
		var shape := CollisionShape2D.new()
		shape.name = "Shape"
		var circle := CircleShape2D.new()
		circle.radius = radius
		shape.shape = circle
		add_child(shape)


func launch(from: Vector2, dir: Vector2, spd: float, dmg: float) -> void:
	global_position = from
	_dir = dir.normalized()
	speed = spd
	damage = dmg
	rotation = _dir.angle()


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	global_position += _dir * speed * delta
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, projectile_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 16, projectile_color.darkened(0.4), 1.0)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
