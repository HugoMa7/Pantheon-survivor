extends Control

# Pre-run screen: pick a starting weapon for this run.
# Writes SaveGame.selected_weapon, then advances to PreRunTrinketPick.

const NEXT_SCENE := "res://ui/PreRunTrinketPick.tscn"

@onready var grid: GridContainer = %Grid
@onready var title: Label = %Title

var _debug_btn: Button


func _ready() -> void:
	title.text = "Choose your starting weapon"
	_populate()
	_build_debug_toggle()


func _build_debug_toggle() -> void:
	_debug_btn = Button.new()
	_debug_btn.anchor_left = 1.0
	_debug_btn.anchor_right = 1.0
	_debug_btn.anchor_top = 1.0
	_debug_btn.anchor_bottom = 1.0
	_debug_btn.offset_left = -175.0
	_debug_btn.offset_right = -8.0
	_debug_btn.offset_top = -42.0
	_debug_btn.offset_bottom = -8.0
	_debug_btn.pressed.connect(_on_debug_toggle)
	add_child(_debug_btn)
	_refresh_debug_btn()


func _refresh_debug_btn() -> void:
	if SaveGame.debug_mode:
		_debug_btn.text = "Debug Mode: ON"
		_debug_btn.modulate = Color(1.0, 0.85, 0.2)
	else:
		_debug_btn.text = "Debug Mode: OFF"
		_debug_btn.modulate = Color(0.6, 0.6, 0.6)


func _on_debug_toggle() -> void:
	SaveGame.debug_mode = not SaveGame.debug_mode
	_refresh_debug_btn()


func _populate() -> void:
	for child in grid.get_children():
		child.queue_free()
	for id in Player.WEAPON_REGISTRY.keys():
		var wd: WeaponData = Player.WEAPON_REGISTRY[id].data
		grid.add_child(_make_card(wd))


func _make_card(wd: WeaponData) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 170)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var desc := wd.description if wd.description != "" else "—"
	btn.text = "%s\n\n%s\n\nDMG: %d   CD: %.1fs" % [
		wd.display_name,
		desc,
		int(wd.base_damage),
		wd.cooldown,
	]
	btn.pressed.connect(func() -> void: _pick(wd.id))
	return btn


func _pick(weapon_id: String) -> void:
	SaveGame.selected_weapon = weapon_id
	SaveGame.save_save()
	get_tree().change_scene_to_file(NEXT_SCENE)
