extends Control

# Pre-run screen: pick one unlocked god to align with at the start of this run.
# Writes SaveGame.selected_god, then advances to PreRunTrinketPick.

const NEXT_SCENE := "res://ui/PreRunTrinketPick.tscn"

@onready var grid: GridContainer = %Grid
@onready var title: Label = %Title


func _ready() -> void:
	title.text = "Choose your patron god"
	_populate()


func _populate() -> void:
	for child in grid.get_children():
		child.queue_free()
	for id in GodCatalog.all_ids():
		if not SaveGame.god_unlocked(str(id)):
			continue
		var god: GodData = GodCatalog.get_god(str(id))
		grid.add_child(_make_card(god))


func _make_card(god: GodData) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 170)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var buff := _buff_text(god)
	var weapon_line := ""
	if god.signature_weapon_id != "":
		weapon_line = "\n(Starts with: %s)" % god.signature_weapon_id.capitalize().replace("_", " ")
	btn.text = "%s\n%s\n\n%s%s" % [god.display_name, god.pantheon.capitalize(), buff, weapon_line]
	btn.pressed.connect(func() -> void: _pick(god.id))
	return btn


func _buff_text(god: GodData) -> String:
	if god.starting_stat_id == "":
		return "— No starting buff —"
	match god.starting_stat_id:
		"move_speed": return "+%d%% Move Speed" % int(god.starting_stat_value * 100)
		"damage": return "+%d%% Damage" % int(god.starting_stat_value * 100)
		"crit_chance": return "+%d%% Crit Chance" % int(god.starting_stat_value * 100)
		"luck": return "+%d Luck" % int(god.starting_stat_value)
		"max_hp": return "+%d Max HP" % int(god.starting_stat_value)
		"projectile_count": return "+%d Projectile" % int(god.starting_stat_value)
		_:
			return "+%s %s" % [str(god.starting_stat_value), god.starting_stat_id]


func _pick(god_id: String) -> void:
	SaveGame.selected_god = god_id
	SaveGame.save_save()
	get_tree().change_scene_to_file(NEXT_SCENE)
