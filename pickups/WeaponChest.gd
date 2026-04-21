class_name WeaponChest extends Area2D

# Interactable chest — press E to pick one unowned weapon.
# Primarily a debug/testing tool spawned at game start.

@export var interact_radius: float = 38.0
@export var chest_color: Color = Color(0.4, 0.85, 1.0, 1.0)

var _player_in_range: bool = false
var _consumed: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player layer
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
		_open()
	queue_redraw()


func _draw() -> void:
	var r := interact_radius * 0.7
	draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), chest_color)
	draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), chest_color.lightened(0.5), false, 2.0)
	draw_rect(Rect2(-r, -r * 0.15, r * 2.0, r * 0.3), chest_color.darkened(0.3))
	draw_arc(Vector2.ZERO, interact_radius + 4.0, 0.0, TAU, 32, chest_color, 1.5)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false


func _open() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	if not player.has_method("available_unowned_weapons") or not player.has_method("add_weapon"):
		return
	if player.slots_free() <= 0:
		_show_toast("No weapon slots available.")
		return

	var available: Array = player.available_unowned_weapons()
	if available.is_empty():
		_show_toast("No new weapons available.")
		return

	_consumed = true
	_show_pick_ui(available, player)


func _show_pick_ui(weapons: Array, player: Node) -> void:
	var screen := CanvasLayer.new()
	screen.layer = 90
	screen.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(screen)
	get_tree().paused = true

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	screen.add_child(dim)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	screen.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Weapon Chest"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)

	for wd: WeaponData in weapons:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 150)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = "%s\n\n%s\n\nDMG: %d   CD: %.1fs" % [
			wd.display_name,
			wd.description if wd.description != "" else "—",
			int(wd.base_damage),
			wd.cooldown,
		]
		btn.pressed.connect(func() -> void:
			player.add_weapon(wd.id)
			get_tree().paused = false
			screen.queue_free()
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.4)
			t.tween_callback(queue_free)
		)
		hb.add_child(btn)


func _show_toast(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(text)
