extends Control

# v1 settings. Manual-aim toggle is disabled — coming in v2 per the plan.

@onready var manual_aim_check: CheckBox = %ManualAimCheck
@onready var back_btn: Button = %BackButton


func _ready() -> void:
	manual_aim_check.disabled = true
	manual_aim_check.text = "Manual aim (coming in v2)"
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
