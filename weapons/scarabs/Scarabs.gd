class_name ScarabSwarm extends Weapon

const PROJECTILE_SCENE = preload("res://weapons/projectile/Projectile.tscn")

@export var scarab_color: Color = Color(0.3, 0.9, 0.55)

var _cd_left: float = 0.6


func _process(delta: float) -> void:
	_cd_left -= delta
	if _cd_left <= 0.0:
		_cd_left = current_cooldown()
		_release()


func _release() -> void:
	var count := current_projectile_count()
	var base_angle := randf() * TAU
	for i in count:
		var angle := base_angle + TAU * float(i) / float(count)
		var dir := Vector2.from_angle(angle)
		var proj: Projectile = PROJECTILE_SCENE.instantiate()
		proj.modulate = scarab_color
		get_tree().current_scene.add_child(proj)
		proj.launch(global_position, dir, current_projectile_speed(), current_damage(), 5.0, 0, true)
