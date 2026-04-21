class_name WeaponStatsPanel extends CanvasLayer

# Persistent overlay showing equipped weapons + god effects + player stats.
# Visible both in-game and during pause. Hover effects show description tooltips.

var _player: Node

var _slot_panels: Array[PanelContainer] = []
var _slot_name_labels: Array[Label] = []
var _slot_effect_boxes: Array[VBoxContainer] = []

var _stat_labels: Dictionary = {}

var _tooltip_panel: PanelContainer
var _tooltip_label: Label

var _refresh_timer: float = 0.0
const REFRESH_INTERVAL := 0.25


func _ready() -> void:
	layer = 82
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_weapon_panel()
	_build_stats_panel()
	_build_tooltip()


func bind_player(player: Node) -> void:
	_player = player
	_refresh_timer = 0.0


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	_update_stats()
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_INTERVAL
		_update_weapons()
	if _tooltip_panel.visible:
		var mp := get_viewport().get_mouse_position()
		_tooltip_panel.position = mp + Vector2(14.0, -_tooltip_panel.size.y - 6.0)


# ── Build ─────────────────────────────────────────────────────────────────────

func _build_weapon_panel() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.anchor_left = 0.12
	root.anchor_right = 0.88
	root.offset_top = -148.0
	root.offset_bottom = -6.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	root.add_child(hbox)

	for i in 3:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(210, 135)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(panel)
		_slot_panels.append(panel)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)

		var fx_box := VBoxContainer.new()
		fx_box.add_theme_constant_override("separation", 1)
		fx_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(fx_box)
		_slot_effect_boxes.append(fx_box)

		var sep := HSeparator.new()
		vbox.add_child(sep)

		var lbl := Label.new()
		lbl.text = "— Empty —"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(lbl)
		_slot_name_labels.append(lbl)


func _build_stats_panel() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -185.0
	panel.offset_right = -5.0
	panel.offset_top = 95.0
	panel.offset_bottom = 390.0
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "STATS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	var keys := ["hp", "speed", "damage", "atk_speed", "crit", "crit_dmg",
				 "armor", "lifesteal", "pickup_r", "xp_mult", "gold_mult", "luck"]
	for k in keys:
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(lbl)
		_stat_labels[k] = lbl


func _build_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.z_index = 10
	add_child(_tooltip_panel)

	_tooltip_label = Label.new()
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.custom_minimum_size = Vector2(220, 0)
	_tooltip_label.add_theme_font_size_override("font_size", 13)
	_tooltip_panel.add_child(_tooltip_label)


# ── Update ────────────────────────────────────────────────────────────────────

func _update_weapons() -> void:
	var weapons: Array = _player.owned_weapons() if _player.has_method("owned_weapons") else []

	for i in 3:
		var fx_box: VBoxContainer = _slot_effect_boxes[i]
		var name_lbl: Label = _slot_name_labels[i]

		for child in fx_box.get_children():
			fx_box.remove_child(child)
			child.free()

		if i >= weapons.size():
			name_lbl.text = "— Empty —"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			continue

		var weapon = weapons[i]
		var wdata = weapon.get("data")
		var wlevel: int = weapon.get("level") if weapon.get("level") != null else 1
		name_lbl.text = "%s  Lv%d" % [wdata.display_name if wdata else "Weapon", wlevel]
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))

		var effects = weapon.get("god_effects")
		if effects == null:
			continue
		var effects_dict := effects as Dictionary
		for eff: String in effects_dict:
			var lvl: int = int(effects_dict[eff])
			var eff_lbl := Label.new()
			var lvl_tag := " Lv%d" % lvl if lvl > 1 else ""
			eff_lbl.text = "⚡ " + GodWeaponEffects.get_display_name(eff) + lvl_tag
			eff_lbl.add_theme_font_size_override("font_size", 11)
			eff_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			eff_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			var desc: String = GodWeaponEffects.get_description(eff)
			var display_name: String = GodWeaponEffects.get_display_name(eff)
			var lvl_copy := lvl
			eff_lbl.mouse_entered.connect(func() -> void:
				_tooltip_label.text = "%s  Lv%d\n%s" % [display_name, lvl_copy, desc]
				_tooltip_panel.visible = true
			)
			eff_lbl.mouse_exited.connect(func() -> void:
				_tooltip_panel.visible = false
			)
			fx_box.add_child(eff_lbl)


func _update_stats() -> void:
	var stats: StatBlock = _player.get_stats() if _player.has_method("get_stats") else null
	if stats == null:
		return

	var max_hp: float = _player.effective_max_hp() if _player.has_method("effective_max_hp") else 0.0
	var cur_hp = _player.get("current_hp")
	var speed: float = _player.effective_move_speed() if _player.has_method("effective_move_speed") else 0.0
	var pickup_r: float = _player.get_pickup_radius() if _player.has_method("get_pickup_radius") else 0.0

	(_stat_labels["hp"] as Label).text        = "HP  %d / %d" % [int(cur_hp if cur_hp else 0), int(max_hp)]
	(_stat_labels["speed"] as Label).text     = "Speed  %d px/s" % int(speed)
	(_stat_labels["damage"] as Label).text    = "Damage  +%d%%" % int(stats.damage_mult * 100)
	(_stat_labels["atk_speed"] as Label).text = "Atk Speed  +%d%%" % int(stats.attack_speed_mult * 100)
	(_stat_labels["crit"] as Label).text      = "Crit  %d%%" % int(stats.crit_chance * 100)
	(_stat_labels["crit_dmg"] as Label).text  = "Crit DMG  +%d%%" % int(stats.crit_damage_mult * 100)
	(_stat_labels["armor"] as Label).text     = "Armor  %d" % int(stats.armor)
	(_stat_labels["lifesteal"] as Label).text = "Lifesteal  %d%%" % int(stats.lifesteal * 100)
	(_stat_labels["pickup_r"] as Label).text  = "Pickup  %dpx" % int(pickup_r)
	(_stat_labels["xp_mult"] as Label).text   = "XP  +%d%%" % int(stats.xp_mult * 100)
	(_stat_labels["gold_mult"] as Label).text = "Gold  +%d%%" % int(stats.gold_mult * 100)
	(_stat_labels["luck"] as Label).text      = "Luck  %d" % stats.luck
