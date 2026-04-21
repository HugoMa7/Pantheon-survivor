class_name XPGem extends Area2D

@export var xp_value: int = 1
@export var magnet_speed: float = 450.0
@export var absorb_distance: float = 20.0

var _player: Node2D
var _magnetized: bool = false


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
		_magnetized = true

	if _magnetized:
		# Pure seek: recalculate direction every frame so the orb always tracks the player's current position.
		global_position += to_player.normalized() * magnet_speed * delta
