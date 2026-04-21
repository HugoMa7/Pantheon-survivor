extends Control

@onready var start_btn: Button = %StartRunButton
@onready var hub_btn: Button = %HubButton
@onready var settings_btn: Button = %SettingsButton
@onready var quit_btn: Button = %QuitButton


func _ready() -> void:
	start_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/PreRunGodPick.tscn"))
	hub_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/Hub.tscn"))
	settings_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://ui/Settings.tscn"))
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
