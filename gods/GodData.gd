class_name GodData extends Resource

# Data-driven god definition.
# Drives pre-run pick (starting buff + signature weapon) and shrine blessing pools.

@export var id: String
@export var display_name: String
@export var pantheon: String                  # "greek" | "norse" | "egyptian"
@export var description: String
@export var color: Color = Color.WHITE

# Pre-run starting buff granted immediately when this god is selected.
@export var starting_stat_id: String = ""     # Player._apply_stat key
@export var starting_stat_value: float = 0.0

# Signature weapon id this god adds to the card pool (empty = blessings only).
@export var signature_weapon_id: String = ""

# v2: in-run weapon-effect upgrades (e.g. "Bolt chains +3"). Left empty in v1.
@export var weapon_effect_modifiers: Array = []
