class_name XPGem extends Area2D

@export var xp_value: int = 1
@export var magnet_accel: float = 1200.0
@export var max_speed: float = 700.0
@export var absorb_distance: float = 14.0

var _velocity: Vector2 = Vector2.ZERO
var _player: Node2D


func _ready() -> void:
	add_to_group("xp_gems")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return
		_player = players[0]

	var to_player: Vector2 = _player.global_position - global_position
	var dist := to_player.length()

	if dist <= absorb_distance:
		if _player.has_method("gain_xp"):
			_player.gain_xp(xp_value)
		queue_free()
		return

	var pickup_radius := 80.0
	if _player.has_method("get_pickup_radius"):
		pickup_radius = _player.get_pickup_radius()

	if dist <= pickup_radius:
		_velocity += to_player.normalized() * magnet_accel * delta
		if _velocity.length() > max_speed:
			_velocity = _velocity.normalized() * max_speed
	else:
		_velocity = _velocity.move_toward(Vector2.ZERO, 200.0 * delta)

	global_position += _velocity * delta
