class_name DebugPanel extends CanvasLayer

# In-game debug overlay. Toggle with F1.
# Spawns, density control, god mode, XP/gold injection.

const DENSITY_VALUES: Array[float] = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0]
const DENSITY_LABELS: Array[String] = ["0.25×", "0.5×", "1× (normal)", "2×", "4×", "8×"]
const DENSITY_DEFAULT: int = 2  # index into above arrays

var _root: PanelContainer
var _god_mode_check: CheckBox
var _density_option: OptionButton
var _status_label: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_F1:
			_root.visible = not _root.visible
			get_viewport().set_input_as_handled()


# ── Build ─────────────────────────────────────────────────────────────────────

func _build() -> void:
	_root = PanelContainer.new()
	_root.anchor_left = 0.0
	_root.anchor_right = 0.0
	_root.anchor_top = 0.0
	_root.anchor_bottom = 0.0
	_root.offset_left = 4.0
	_root.offset_top = 4.0
	_root.offset_right = 220.0
	_root.offset_bottom = 460.0
	add_child(_root)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_root.add_child(vb)

	# Header
	var header := Label.new()
	header.text = "⚙ DEBUG  [F1]"
	header.add_theme_font_size_override("font_size", 14)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(header)
	vb.add_child(HSeparator.new())

	# ── Spawns ────────────────────────────────────────────────────────────────
	vb.add_child(_section_label("SPAWNS"))

	var spawn_hb1 := HBoxContainer.new()
	spawn_hb1.add_theme_constant_override("separation", 4)
	vb.add_child(spawn_hb1)
	spawn_hb1.add_child(_btn("Altar", _on_spawn_altar))
	spawn_hb1.add_child(_btn("Chest", _on_spawn_chest))
	spawn_hb1.add_child(_btn("Elite", _on_spawn_elite))

	vb.add_child(HSeparator.new())

	# ── Enemies ───────────────────────────────────────────────────────────────
	vb.add_child(_section_label("ENEMIES"))

	var dens_hb := HBoxContainer.new()
	dens_hb.add_theme_constant_override("separation", 4)
	vb.add_child(dens_hb)
	var dens_lbl := Label.new()
	dens_lbl.text = "Density"
	dens_lbl.add_theme_font_size_override("font_size", 12)
	dens_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	dens_hb.add_child(dens_lbl)

	_density_option = OptionButton.new()
	_density_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lbl in DENSITY_LABELS:
		_density_option.add_item(lbl)
	_density_option.selected = DENSITY_DEFAULT
	_density_option.item_selected.connect(_on_density_changed)
	dens_hb.add_child(_density_option)

	vb.add_child(_btn("Kill All Enemies", _on_kill_all))

	vb.add_child(HSeparator.new())

	# ── Player ────────────────────────────────────────────────────────────────
	vb.add_child(_section_label("PLAYER"))

	_god_mode_check = CheckBox.new()
	_god_mode_check.text = "God Mode"
	_god_mode_check.add_theme_font_size_override("font_size", 12)
	_god_mode_check.toggled.connect(_on_god_mode_toggled)
	vb.add_child(_god_mode_check)

	var xp_gold_hb := HBoxContainer.new()
	xp_gold_hb.add_theme_constant_override("separation", 4)
	vb.add_child(xp_gold_hb)
	xp_gold_hb.add_child(_btn("+1000 XP", _on_give_xp))
	xp_gold_hb.add_child(_btn("+100 Gold", _on_give_gold))

	var heal_hb := HBoxContainer.new()
	heal_hb.add_theme_constant_override("separation", 4)
	vb.add_child(heal_hb)
	heal_hb.add_child(_btn("Full Heal", _on_full_heal))
	heal_hb.add_child(_btn("+1 Level", _on_level_up))

	vb.add_child(HSeparator.new())

	# ── Status ────────────────────────────────────────────────────────────────
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_status_label)


func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	return lbl


func _btn(text: String, callable: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(callable)
	return b


# ── Helpers ───────────────────────────────────────────────────────────────────

func _event_director() -> Node:
	return get_tree().get_first_node_in_group("event_director")


func _wave_director() -> Node:
	return get_tree().get_first_node_in_group("wave_director")


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _toast(text: String) -> void:
	_status_label.text = text


# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_spawn_altar() -> void:
	var ed := _event_director()
	if ed and ed.has_method("spawn_altar_now"):
		ed.spawn_altar_now()
		_toast("Altar spawned.")
	else:
		_toast("EventDirector not found.")


func _on_spawn_chest() -> void:
	var ed := _event_director()
	if ed and ed.has_method("spawn_chest_now"):
		ed.spawn_chest_now()
		_toast("Chest spawned.")
	else:
		_toast("EventDirector not found.")


func _on_spawn_elite() -> void:
	var ed := _event_director()
	if ed and ed.has_method("spawn_elite_now"):
		ed.spawn_elite_now()
		_toast("Elite spawned.")
	else:
		_toast("EventDirector not found.")


func _on_kill_all() -> void:
	var count := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.has_method("take_damage"):
			var hp_val = e.get("current_hp")
			if hp_val != null:
				e.take_damage(float(hp_val) + 99999.0)
				count += 1
	_toast("Killed %d enemies." % count)


func _on_density_changed(index: int) -> void:
	var wd := _wave_director()
	if wd:
		wd.set("debug_density_mult", DENSITY_VALUES[index])
	_toast("Density: %s" % DENSITY_LABELS[index])


func _on_god_mode_toggled(pressed: bool) -> void:
	var p := _player()
	if p:
		p.set("debug_god_mode", pressed)
	_toast("God mode: %s" % ("ON" if pressed else "OFF"))


func _on_give_xp() -> void:
	var p := _player()
	if p and p.has_method("gain_xp"):
		p.gain_xp(1000)
		_toast("+1000 XP.")


func _on_give_gold() -> void:
	var p := _player()
	if p and p.has_method("gain_gold"):
		p.gain_gold(100)
		_toast("+100 Gold.")


func _on_full_heal() -> void:
	var p := _player()
	if p and p.has_method("heal") and p.has_method("effective_max_hp"):
		p.heal(p.call("effective_max_hp"))
		_toast("Full heal.")


func _on_level_up() -> void:
	var p := _player()
	if p and p.has_method("gain_xp") and p.has_method("_xp_for_next_level"):
		var needed: int = p.call("_xp_for_next_level", p.get("level"))
		var current: int = p.get("current_xp")
		p.gain_xp(needed - current)
		_toast("+1 level.")
