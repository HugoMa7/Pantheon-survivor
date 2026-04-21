class_name Shrine extends Area2D

# Divine Shrine — interact to pick 1 of 3 blessings from unlocked gods.
# Stacks across multiple shrines per run (no primary-god lock).

signal used(blessing: Blessing)

@export var interact_radius: float = 36.0
@export var shrine_color: Color = Color(0.6, 0.85, 1.0, 1)

var _player_in_range: bool = false
var _consumed: bool = false


func _ready() -> void:
	add_to_group("shrine")
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
	if _consumed:
		return
	if _player_in_range and Input.is_action_just_pressed("interact"):
		_open_screen()
	# subtle pulse
	modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.004)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, interact_radius * 0.6, shrine_color)
	draw_arc(Vector2.ZERO, interact_radius, 0.0, TAU, 32, shrine_color.darkened(0.2), 2.0)
	if _player_in_range and not _consumed:
		# "press E" prompt ring
		draw_arc(Vector2.ZERO, interact_radius + 8.0, 0.0, TAU, 32, Color.WHITE, 1.0)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false


func _open_screen() -> void:
	var unlocked: Array = SaveGame.unlocked_gods.duplicate()
	if unlocked.is_empty():
		return
	var options := BlessingCatalog.draw_from_unlocked(unlocked, 3)
	if options.is_empty():
		return
	var screen_scene: PackedScene = preload("res://ui/ShrineScreen.tscn")
	var screen = screen_scene.instantiate()
	get_tree().current_scene.add_child(screen)
	screen.bind_and_open(options, func(choice: Blessing) -> void:
		if choice != null:
			_apply_choice(choice)
	)


func _apply_choice(b: Blessing) -> void:
	_consumed = true
	used.emit(b)
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_blessing_resource"):
		player.apply_blessing_resource(b)
	# fade out + remove
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)
