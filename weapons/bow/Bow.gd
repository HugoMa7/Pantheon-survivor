class_name HuntersBow extends Weapon

const PROJECTILE_SCENE = preload("res://weapons/projectile/Projectile.tscn")

@export var arrow_color: Color = Color(0.95, 0.88, 0.5)
@export var max_target_range: float = 800.0

var _cd_left: float = 0.3


func _process(delta: float) -> void:
	_cd_left -= delta
	if _cd_left <= 0.0:
		_cd_left = current_cooldown()
		_fire()


func _fire() -> void:
	var target := EnemyQuery.nearest(get_tree(), global_position, max_target_range)
	if not target:
		return
	var dir := (target.global_position - global_position).normalized()
	var count := current_projectile_count()
	var base_angle := dir.angle()
	var spread_step := deg_to_rad(10.0)
	for i in count:
		var angle := base_angle
		if count > 1:
			angle += spread_step * (float(i) - float(count - 1) / 2.0)
		var proj: Projectile = PROJECTILE_SCENE.instantiate()
		proj.modulate = arrow_color
		get_tree().current_scene.add_child(proj)
		proj.launch(global_position, Vector2.from_angle(angle), current_projectile_speed(), current_damage(), 2.5, 0, false)
