class_name EnemyData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_enum("grunt", "tank", "speed", "ranged", "mage", "elite", "boss") var category: String = "grunt"

@export_group("Combat")
@export var base_hp: float = 10.0
@export var base_damage: float = 5.0
@export var base_speed: float = 60.0
@export var size: float = 1.0
@export var is_ranged: bool = false
@export var attack_range: float = 0.0
@export var projectile_speed: float = 0.0
@export var attack_cooldown: float = 1.0
@export_enum("melee_contact", "ranged_linear", "charge", "burst_area") var attack_pattern: String = "melee_contact"

@export_group("Drops")
@export var xp_value: int = 1
@export var gold_drop_chance: float = 0.0
@export var gold_drop_min: int = 0
@export var gold_drop_max: int = 0

@export_group("Visual")
@export var color: Color = Color(0.6, 0.2, 0.7)
@export var sprite: Texture2D
@export var death_fx: PackedScene
