class_name HiddenAltar extends Area2D

# Rare shrine variant — interacting permanently unlocks a locked god.
# Only spawns while remaining_locked_gods() is non-empty.

signal used(god_id: String)

@export var interact_radius: float = 40.0
@export var altar_color: Color = Color(0.95, 0.3, 0.85, 1)

var _player_in_range: bool = false
var _consumed: bool = false


func _ready() -> void:
	add_to_group("hidden_altar")
	collision_layer = 0
	collision_mask = 2  # player
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = interact_radius
	shape.shape = circle
	add_child(shape)
	queue_redraw()


func _process(_delta: float) -> void:
	if _player_in_range and not _consumed and Input.is_action_just_pressed("interact"):
		_consume()
	queue_redraw()


func _draw() -> void:
	# swirling diamond silhouette distinct from regular shrines
	var r := interact_radius
	var points := PackedVector2Array([
		Vector2(0, -r * 0.9),
		Vector2(r * 0.75, 0),
		Vector2(0, r * 0.9),
		Vector2(-r * 0.75, 0),
	])
	draw_colored_polygon(points, altar_color)
	draw_arc(Vector2.ZERO, r + 6.0, 0.0, TAU, 32, altar_color.lightened(0.3), 2.0)
	draw_arc(Vector2.ZERO, r + 14.0, 0.0, TAU, 32, altar_color.darkened(0.3), 1.0)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false


func _consume() -> void:
	var locked := SaveGame.remaining_locked_gods()
	if locked.is_empty():
		return
	_consumed = true
	var picked: String = locked[randi() % locked.size()]
	SaveGame.unlock_god(picked)
	used.emit(picked)
	var god := GodCatalog.get_god(picked)
	var name := (god.display_name if god else picked.capitalize())
	_show_toast("%s unlocked!" % name)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)


func _show_toast(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(text)
