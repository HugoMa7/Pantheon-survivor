class_name Blessing extends Resource

# A single shrine blessing option — applied to the player as a stat/blessing bump.

@export var id: String
@export var display_name: String
@export var description: String
@export var stat_id: String       # matches Player._apply_stat / _apply_blessing keys
@export var value: float = 0.0
@export var is_blessing_effect: bool = false  # true → routes through _apply_blessing
