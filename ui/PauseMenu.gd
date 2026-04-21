class_name PauseMenu extends CanvasLayer

# Toggled with the "pause" action (ESC). Hidden by default.
# Game is paused while visible; process_mode=ALWAYS so this UI still runs.

@onready var resume_btn: Button = %ResumeButton
@onready var hub_btn: Button = %HubButton
@onready var menu_btn: Button = %MenuButton


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_btn.pressed.connect(_on_resume)
	hub_btn.pressed.connect(_on_hub)
	menu_btn.pressed.connect(_on_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		_close()
	else:
		_open()


func _open() -> void:
	visible = true
	get_tree().paused = true


func _close() -> void:
	visible = false
	get_tree().paused = false


func _on_resume() -> void:
	_close()


func _on_hub() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
