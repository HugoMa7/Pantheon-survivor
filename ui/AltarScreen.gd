class_name AltarScreen extends CanvasLayer

# Two-phase modal for the Altar of Gods.
# Phase 1: pick 1 of 3 random gods (no reroll).
# Phase 2: pick 1 of 3 random effects from that god's pool (3 base rerolls).
# Repicking an already-owned effect increments its level (max 3).

var _on_complete: Callable = Callable()
var _god_ids: Array[String] = []
var _panel: PanelContainer
var _rerolls: int = 3
var _reroll_btn: Button

# Stored so reroll can regenerate a new 3-pick from the same god.
var _current_god_id: String = ""
var _current_effect_ids: Array[String] = []


func _ready() -> void:
	layer = 92
	process_mode = Node.PROCESS_MODE_ALWAYS


func open(god_ids: Array[String], on_complete: Callable) -> void:
	_god_ids = god_ids
	_on_complete = on_complete
	_build_god_phase()
	get_tree().paused = true


func _clear() -> void:
	for c in get_children():
		c.queue_free()


# ── Phase 1: God selection (no reroll here) ─────────────────────────────────

func _build_god_phase() -> void:
	_clear()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	add_child(dim)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_panel = PanelContainer.new()
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	_panel.add_child(vb)

	var title := Label.new()
	title.text = "Altar of the Gods"
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "Choose a deity to receive their blessing"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)

	for gid: String in _god_ids:
		hb.add_child(_make_god_card(gid))


func _make_god_card(god_id: String) -> Control:
	var god: GodData = GodCatalog.get_god(god_id)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 160)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var is_new := god_id not in SaveGame.interacted_gods
	var tag := " ✦ First Contact!" if is_new else ""
	var name_str := (god.display_name if god else god_id.capitalize())
	var pan_str := (god.pantheon.capitalize() if god else "")
	btn.text = "%s\n%s\n%s" % [name_str, pan_str, tag]
	if god:
		btn.modulate = god.color.lightened(0.2)
	btn.pressed.connect(func() -> void: _on_god_picked(god_id))
	return btn


func _on_god_picked(god_id: String) -> void:
	SaveGame.record_god_interaction(god_id)
	_current_god_id = god_id
	_current_effect_ids = _pick_three_effects(god_id)
	_build_upgrade_phase()


# ── Phase 2: Upgrade selection (reroll here) ────────────────────────────────

func _pick_three_effects(god_id: String) -> Array[String]:
	var all := GodWeaponEffects.effects_for_god(god_id)
	all.shuffle()
	var result: Array[String] = []
	for i in min(3, all.size()):
		result.append(all[i])
	return result


func _build_upgrade_phase() -> void:
	_clear()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	add_child(dim)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_panel = PanelContainer.new()
	center.add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	_panel.add_child(vb)

	var god: GodData = GodCatalog.get_god(_current_god_id)
	var title := Label.new()
	title.text = "Blessing of %s" % (god.display_name if god else _current_god_id.capitalize())
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var player := get_tree().get_first_node_in_group("player")
	var weapons: Array = player.owned_weapons() if player and player.has_method("owned_weapons") else []
	var weapon_names := ", ".join(weapons.map(func(w) -> String:
		var d = w.get("data")
		return d.display_name if d else "?"
	))

	var sub := Label.new()
	sub.text = "Applies to all equipped weapons: %s" % weapon_names
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)

	for effect_id in _current_effect_ids:
		hb.add_child(_make_upgrade_card(effect_id, weapons))

	_reroll_btn = Button.new()
	_reroll_btn.text = "Reroll  (%d remaining)" % _rerolls
	_reroll_btn.disabled = _rerolls <= 0
	_reroll_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reroll_btn.pressed.connect(_on_reroll)
	vb.add_child(_reroll_btn)


func _on_reroll() -> void:
	if _rerolls <= 0:
		return
	_rerolls -= 1
	_current_effect_ids = _pick_three_effects(_current_god_id)
	_build_upgrade_phase()


func _make_upgrade_card(effect_id: String, weapons: Array) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 190)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var current_lvl: int = 0
	for w in weapons:
		var fx = w.get("god_effects")
		if fx != null:
			var lvl_val = (fx as Dictionary).get(effect_id, 0)
			current_lvl = max(current_lvl, int(lvl_val))

	var at_max: bool = current_lvl >= 3
	var level_tag: String
	if current_lvl == 0:
		level_tag = ""
	elif at_max:
		level_tag = "\n[MAX LEVEL]"
	else:
		level_tag = "\n[Lv%d → Lv%d]" % [current_lvl, current_lvl + 1]

	btn.text = "%s%s\n\n%s" % [
		GodWeaponEffects.get_display_name(effect_id),
		level_tag,
		GodWeaponEffects.get_description(effect_id),
	]

	btn.pressed.connect(func() -> void: _on_upgrade_picked(effect_id, weapons))
	return btn


func _on_upgrade_picked(effect_id: String, weapons: Array) -> void:
	for weapon in weapons:
		var fx_val = weapon.get("god_effects")
		if fx_val == null:
			continue
		var fx := fx_val as Dictionary
		var cur_lvl: int = fx.get(effect_id, 0)
		if cur_lvl < 3:
			fx[effect_id] = cur_lvl + 1
			if effect_id == "bastet_nine_lives":
				weapon.nine_lives_charges = fx[effect_id]

	get_tree().paused = false
	if _on_complete.is_valid():
		_on_complete.call()
	queue_free()
