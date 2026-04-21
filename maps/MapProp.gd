extends Node2D

# Lightweight procedural props: broken columns, braziers, altar — all drawn via _draw.
# Placeholders for coherent pixel art in the asset-sourcing pass.

enum Kind { COLUMN, ALTAR, BRAZIER }

@export var kind: Kind = Kind.COLUMN
@export var tint: Color = Color(0.85, 0.82, 0.75)

var _flicker_phase: float = 0.0


func _ready() -> void:
	_flicker_phase = randf() * TAU


func _process(delta: float) -> void:
	if kind == Kind.BRAZIER:
		_flicker_phase += delta * 6.0
		queue_redraw()


func _draw() -> void:
	match kind:
		Kind.COLUMN:
			_draw_column()
		Kind.ALTAR:
			_draw_altar()
		Kind.BRAZIER:
			_draw_brazier()


func _draw_column() -> void:
	# Broken marble column: stacked capital + shaft + base, with a crack.
	var shaft_rect := Rect2(Vector2(-12, -54), Vector2(24, 70))
	draw_rect(shaft_rect, tint)
	draw_rect(shaft_rect, tint.darkened(0.3), false, 1.0)
	# capital
	draw_rect(Rect2(Vector2(-18, -62), Vector2(36, 10)), tint.lightened(0.1))
	# base
	draw_rect(Rect2(Vector2(-18, 16), Vector2(36, 8)), tint.darkened(0.15))
	# crack
	draw_line(Vector2(-6, -30), Vector2(6, 8), tint.darkened(0.55), 1.5)


func _draw_altar() -> void:
	# Central altar: a stepped stone block with a faint glowing seam.
	draw_rect(Rect2(Vector2(-48, -22), Vector2(96, 44)), tint.darkened(0.1))
	draw_rect(Rect2(Vector2(-48, -22), Vector2(96, 44)), tint.darkened(0.4), false, 2.0)
	draw_rect(Rect2(Vector2(-36, -32), Vector2(72, 10)), tint)
	draw_line(Vector2(-40, 0), Vector2(40, 0), Color(1.0, 0.9, 0.5, 0.8), 2.0)


func _draw_brazier() -> void:
	# Bowl + flickering flame
	draw_rect(Rect2(Vector2(-3, -4), Vector2(6, 22)), Color(0.45, 0.35, 0.28))
	var bowl_color := Color(0.55, 0.45, 0.35)
	draw_rect(Rect2(Vector2(-12, -10), Vector2(24, 6)), bowl_color)
	var flame_size: float = 12.0 + sin(_flicker_phase) * 2.0
	draw_circle(Vector2(0, -18), flame_size, Color(1.0, 0.65, 0.2, 0.9))
	draw_circle(Vector2(0, -20), flame_size * 0.55, Color(1.0, 0.9, 0.45, 1.0))
