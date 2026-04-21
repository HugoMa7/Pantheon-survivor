class_name VictoryScreen extends CanvasLayer

# Shown on final boss kill. Displays run stats and returns to the Hub.

@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel
@onready var gold_label: Label = %GoldLabel
@onready var return_btn: Button = %ReturnButton


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	return_btn.pressed.connect(_on_return)


func show_stats(elapsed_sec: float, level: int, gold_earned: int) -> void:
	var m := int(elapsed_sec / 60.0)
	var s := int(elapsed_sec) % 60
	time_label.text = "Time: %d:%02d" % [m, s]
	level_label.text = "Level: %d" % level
	gold_label.text = "Gold earned: %d" % gold_earned
	get_tree().paused = true


func _on_return() -> void:
	get_tree().paused = false
	# Grant earned gold to the save
	# Hub scene (to be built in Step 8) — for now just reload Main as a temporary fallback
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")
