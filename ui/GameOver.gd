class_name GameOverScreen extends CanvasLayer

# Shown on player death. Grants earned gold and returns to Hub / retry.

@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel
@onready var gold_label: Label = %GoldLabel
@onready var hub_btn: Button = %HubButton
@onready var retry_btn: Button = %RetryButton


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	hub_btn.pressed.connect(_on_hub)
	retry_btn.pressed.connect(_on_retry)


func show_stats(elapsed_sec: float, level: int, gold_earned: int) -> void:
	var m := int(elapsed_sec / 60.0)
	var s := int(elapsed_sec) % 60
	time_label.text = "Time survived: %d:%02d" % [m, s]
	level_label.text = "Level reached: %d" % level
	gold_label.text = "Gold earned: %d" % gold_earned
	get_tree().paused = true


func _on_hub() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")


func _on_retry() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
