class_name AltarOfGods extends Area2D

# Interactable altar: player picks a god → picks a weapon upgrade.
# Spawns on elite death (100%) and randomly on the map (low chance).

const ALTAR_SCREEN_SCENE := preload("res://ui/AltarScreen.tscn")

@export var interact_radius: float = 44.0
@export var altar_color: Color = Color(1.0, 0.85, 0.3, 1.0)

var _player_in_range: bool = false
var _consumed: bool = false


func _ready() -> void:
	add_to_group("altar_of_gods")
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
	var r := interact_radius
	# Starburst / pillar silhouette distinct from shrines and hidden altars
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var outer := Vector2.from_angle(angle) * r * 0.95
		var inner := Vector2.from_angle(angle + TAU / 16.0) * r * 0.5
		draw_line(Vector2.ZERO, outer, altar_color, 2.5)
		draw_line(Vector2.ZERO, inner, altar_color.lightened(0.4), 1.5)
	draw_circle(Vector2.ZERO, r * 0.22, altar_color)
	draw_arc(Vector2.ZERO, r + 5.0, 0.0, TAU, 40, altar_color.lightened(0.3), 2.0)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false


func _open() -> void:
	_consumed = true
	var god_ids := _pick_three_gods()
	var screen: AltarScreen = ALTAR_SCREEN_SCENE.instantiate()
	get_tree().current_scene.add_child(screen)
	screen.open(god_ids, _on_choice_made)


func _pick_three_gods() -> Array[String]:
	var all: Array[String] = []
	for id in GodCatalog.all_ids():
		all.append(str(id))
	all.shuffle()
	var result: Array[String] = []
	for i in min(3, all.size()):
		result.append(all[i])
	return result


func _on_choice_made() -> void:
	_show_toast("The gods have spoken.")
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)


func _show_toast(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(text)
