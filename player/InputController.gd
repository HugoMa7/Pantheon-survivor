extends Node

enum AimMode { AUTO, MANUAL }

var aim_mode: AimMode = AimMode.AUTO


func get_move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func get_aim_direction(from: Vector2) -> Vector2:
	if aim_mode == AimMode.MANUAL:
		var camera := get_tree().root.get_camera_2d()
		if camera:
			return (camera.get_global_mouse_position() - from).normalized()
	return Vector2.ZERO


func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed("interact")
