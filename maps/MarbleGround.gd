extends Node2D

# Draws a large marble-style grid to stand in for a tileset until pixel art lands.

@export var half_extent: Vector2 = Vector2(2000, 2000)
@export var tile_size: float = 64.0
@export var color_a: Color = Color(0.26, 0.24, 0.28)
@export var color_b: Color = Color(0.22, 0.20, 0.24)
@export var grout: Color = Color(0.15, 0.13, 0.17)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var cols: int = int((half_extent.x * 2.0) / tile_size) + 1
	var rows: int = int((half_extent.y * 2.0) / tile_size) + 1
	var origin: Vector2 = -half_extent
	for y in rows:
		for x in cols:
			var pos: Vector2 = origin + Vector2(x * tile_size, y * tile_size)
			var c: Color = color_a if (x + y) % 2 == 0 else color_b
			draw_rect(Rect2(pos, Vector2(tile_size, tile_size)), c)
	# grout lines
	for x in cols + 1:
		var gx: float = origin.x + x * tile_size
		draw_line(Vector2(gx, origin.y), Vector2(gx, origin.y + rows * tile_size), grout, 1.0)
	for y in rows + 1:
		var gy: float = origin.y + y * tile_size
		draw_line(Vector2(origin.x, gy), Vector2(origin.x + cols * tile_size, gy), grout, 1.0)
