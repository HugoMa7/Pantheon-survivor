extends CanvasLayer

@onready var hp_label: Label = %HPLabel
@onready var hp_bar: ProgressBar = %HPBar
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var timer_label: Label = %TimerLabel
@onready var gold_label: Label = %GoldLabel
@onready var toast_container: VBoxContainer = %ToastContainer

var elapsed: float = 0.0


func _ready() -> void:
	layer = 10
	add_to_group("hud")


func bind_player(player: Player) -> void:
	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.gold_changed.connect(_on_gold_changed)


func _process(delta: float) -> void:
	elapsed += delta
	var m := int(elapsed / 60.0)
	var s := int(elapsed) % 60
	timer_label.text = "%d:%02d" % [m, s]


func get_elapsed() -> float:
	return elapsed


func show_toast(text: String, duration: float = 3.0) -> void:
	if toast_container == null:
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_container.add_child(lbl)
	var t := create_tween()
	t.tween_interval(duration)
	t.tween_property(lbl, "modulate:a", 0.0, 0.4)
	t.tween_callback(lbl.queue_free)


func _on_health_changed(current: float, maxh: float) -> void:
	hp_label.text = "HP %d / %d" % [int(ceil(current)), int(maxh)]
	hp_bar.max_value = maxh
	hp_bar.value = current


func _on_xp_changed(cur: int, to_next: int, lvl: int) -> void:
	level_label.text = "Lv %d" % lvl
	xp_bar.max_value = to_next
	xp_bar.value = cur


func _on_gold_changed(g: int) -> void:
	gold_label.text = "Gold %d" % g
