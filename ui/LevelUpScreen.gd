extends CanvasLayer

signal card_picked(card: UpgradeCard)

@export var player_path: NodePath

@onready var cards_row: HBoxContainer = %CardsRow
@onready var title: Label = %Title

var _cards: Array = []
var _pending_levels: int = 0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	if not player_path.is_empty():
		var p := get_node(player_path)
		if p and p.has_signal("leveled_up"):
			p.leveled_up.connect(_on_leveled_up)


func _on_leveled_up(_new_level: int) -> void:
	_pending_levels += 1
	if not visible:
		_open_next()


func _open_next() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	_cards = UpgradePool.draw_cards(players[0], 3)
	if _cards.is_empty():
		_pending_levels = 0
		return
	_populate_cards()
	title.text = "Level Up!"
	show()
	get_tree().paused = true


func _populate_cards() -> void:
	for c in cards_row.get_children():
		c.queue_free()
	for i in _cards.size():
		var card: UpgradeCard = _cards[i]
		cards_row.add_child(_make_card_panel(card, i))


func _make_card_panel(card: UpgradeCard, idx: int) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 300)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.16, 0.95)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = UpgradeCard.rarity_color(card.rarity)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var name_lbl := Label.new()
	name_lbl.text = card.display_name
	name_lbl.add_theme_color_override("font_color", UpgradeCard.rarity_color(card.rarity))
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = _type_label(card)
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(type_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = card.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(desc_lbl)

	var btn := Button.new()
	btn.text = "Pick"
	btn.custom_minimum_size = Vector2(0, 40)
	btn.pressed.connect(_on_card_pressed.bind(idx))
	vb.add_child(btn)

	return panel


func _type_label(card: UpgradeCard) -> String:
	match card.type:
		UpgradeCard.Type.WEAPON_NEW: return "New Weapon"
		UpgradeCard.Type.WEAPON_UPGRADE: return "Weapon Upgrade"
		UpgradeCard.Type.STAT: return "Stat"
		UpgradeCard.Type.BLESSING: return "Blessing"
	return ""


func _on_card_pressed(idx: int) -> void:
	if idx < 0 or idx >= _cards.size():
		return
	var card: UpgradeCard = _cards[idx]
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		players[0].apply_card(card)
	card_picked.emit(card)
	_pending_levels = max(0, _pending_levels - 1)
	if _pending_levels > 0:
		_open_next()
	else:
		get_tree().paused = false
		hide()
