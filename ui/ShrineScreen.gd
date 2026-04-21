class_name ShrineScreen extends CanvasLayer

# Modal UI for picking 1 of N blessings from a shrine.
# Pauses the game while open; resumes on selection.

var _options: Array = []
var _on_pick: Callable = Callable()


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS


func bind_and_open(options: Array, on_pick: Callable) -> void:
	_options = options
	_on_pick = on_pick
	_build_ui()
	get_tree().paused = true


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	add_child(dim)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "Pray at the Shrine"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	vb.add_child(hb)

	for i in _options.size():
		var b: Blessing = _options[i]
		hb.add_child(_make_card(b))


func _make_card(b: Blessing) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 140)
	btn.text = "%s\n\n%s" % [b.display_name, b.description]
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.pressed.connect(func() -> void: _pick(b))
	return btn


func _pick(b: Blessing) -> void:
	if _on_pick.is_valid():
		_on_pick.call(b)
	get_tree().paused = false
	queue_free()
