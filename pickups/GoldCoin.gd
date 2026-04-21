class_name GoldCoin extends Area2D

# A coin drop. Auto-magnetizes to the player when within pickup radius
# and grants a configurable gold amount on touch.

@export var amount: int = 1
@export var magnet_speed: float = 520.0
@export var magnet_accel: float = 1400.0
@export var fly_color: Color = Color(1.0, 0.85, 0.25)

var _player: Node2D
var _velocity: Vector2 = Vector2.ZERO
var _magnetized: bool = false


func _ready() -> void:
	add_to_group("gold_coin")
	collision_layer = 8   # pickup
	collision_mask = 2    # player
	body_entered.connect(_on_body_entered)
	if not has_node("Shape"):
		var shape := CollisionShape2D.new()
		shape.name = "Shape"
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
		add_child(shape)
	queue_redraw()


func _process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var to: Vector2 = _player.global_position - global_position
	var dist: float = to.length()
	var radius: float = 90.0
	if _player.has_method("get_pickup_radius"):
		radius = _player.get_pickup_radius()
	if _magnetized or dist <= radius:
		_magnetized = true
		var dir: Vector2 = to.normalized()
		_velocity = _velocity.move_toward(dir * magnet_speed, magnet_accel * delta)
		global_position += _velocity * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, fly_color)
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 16, fly_color.darkened(0.3), 1.0)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("gain_gold"):
		body.gain_gold(amount)
		queue_free()
