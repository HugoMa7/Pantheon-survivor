extends Node2D

# Procedurally-drawn Defend Olympus arena — v1 placeholder art.
# - Marble tile pattern on the ground (via _draw on a node covering the arena)
# - Scattered broken columns + braziers as child Node2Ds
# - Central altar prop
# - Sky overlay that darkens as the run progresses (drives tension)

@export var arena_half_width: float = 2000.0
@export var arena_half_height: float = 2000.0
@export var run_duration: float = 1800.0  # kept in sync with WaveDirector for timing
@export var sky_start_color: Color = Color(0.08, 0.10, 0.16, 0.15)
@export var sky_end_color: Color = Color(0.55, 0.10, 0.12, 0.55)

@onready var sky_overlay: ColorRect = %SkyOverlay

var _elapsed: float = 0.0


func _ready() -> void:
	sky_overlay.color = sky_start_color


func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clamp(_elapsed / run_duration, 0.0, 1.0)
	# Curved tension: ramps up more toward end
	var eased: float = pow(t, 1.4)
	sky_overlay.color = sky_start_color.lerp(sky_end_color, eased)
