extends Control

# Pre-run screen: equip zero or one unlocked trinket for this run.
# Writes SaveGame.selected_trinket, then starts Main.

const NEXT_SCENE := "res://scenes/Main.tscn"

@onready var grid: GridContainer = %Grid
@onready var title: Label = %Title


func _ready() -> void:
	title.text = "Equip a trinket"
	_populate()


func _populate() -> void:
	for child in grid.get_children():
		child.queue_free()
	grid.add_child(_make_none_card())
	for id in TrinketCatalog.all_ids():
		if not SaveGame.trinket_unlocked(str(id)):
			continue
		var t: Trinket = TrinketCatalog.get_trinket(str(id))
		grid.add_child(_make_card(t))


func _make_none_card() -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 150)
	btn.text = "No Trinket\n\nBegin the run empty-handed."
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.pressed.connect(func() -> void: _pick(""))
	return btn


func _make_card(t: Trinket) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 150)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.text = "%s\n\n%s" % [t.display_name, t.description]
	btn.pressed.connect(func() -> void: _pick(t.id))
	return btn


func _pick(id: String) -> void:
	SaveGame.selected_trinket = id
	SaveGame.save_save()
	get_tree().change_scene_to_file(NEXT_SCENE)
