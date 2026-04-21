class_name Trinket extends Resource

# A Hades-style keepsake equipped at run start for a run-long passive.
# `effects` is a list of dicts: { "stat_id": String, "value": float, "is_blessing": bool }
# Routed through Player._apply_stat (is_blessing=false) or _apply_blessing (is_blessing=true).

@export var id: String
@export var display_name: String
@export var description: String
@export var color: Color = Color(0.9, 0.9, 0.95)
@export var effects: Array = []
