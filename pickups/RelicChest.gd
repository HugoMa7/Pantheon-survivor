class_name RelicChest extends Area2D

# Dropped by elites and the final boss. Interacting permanently unlocks a random
# locked trinket. If all trinkets are already unlocked, grants a small gold pile
# instead so the chest never feels like a dud.

signal opened(trinket_id: String)

@export var interact_radius: float = 28.0
@export var fallback_gold_min: int = 25
@export var fallback_gold_max: int = 50
@export var chest_color: Color = Color(0.95, 0.75, 0.3, 1)

var _player_in_range: bool = false
var _consumed: bool = false


func _ready() -> void:
	add_to_group("relic_chest")
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
		_open()
	queue_redraw()


func _draw() -> void:
	# stylized chest silhouette: square body + lid line
	var r := interact_radius
	var body_rect := Rect2(Vector2(-r * 0.7, -r * 0.5), Vector2(r * 1.4, r * 1.0))
	draw_rect(body_rect, chest_color)
	draw_rect(body_rect, chest_color.darkened(0.4), false, 2.0)
	draw_line(Vector2(-r * 0.7, -r * 0.1), Vector2(r * 0.7, -r * 0.1), chest_color.darkened(0.4), 2.0)
	if _player_in_range and not _consumed:
		draw_arc(Vector2.ZERO, r + 8.0, 0.0, TAU, 24, Color.WHITE, 1.0)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false


func _open() -> void:
	_consumed = true
	var locked := TrinketCatalog.remaining_locked()
	if locked.is_empty():
		var amount: int = fallback_gold_min + randi() % max(1, fallback_gold_max - fallback_gold_min + 1)
		var player: Node = get_tree().get_first_node_in_group("player")
		if player and player.has_method("gain_gold"):
			player.gain_gold(amount)
		_toast("+%d gold (all trinkets unlocked)" % amount)
		opened.emit("")
	else:
		var picked: String = locked[randi() % locked.size()]
		SaveGame.unlock_trinket(picked)
		var t := TrinketCatalog.get_trinket(picked)
		_toast("Trinket unlocked: %s" % (t.display_name if t else picked.capitalize()))
		opened.emit(picked)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)


func _toast(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(text, 3.5)
