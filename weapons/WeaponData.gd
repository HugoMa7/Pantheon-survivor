class_name WeaponData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_enum("neutral", "greek", "norse", "egyptian") var pantheon: String = "neutral"
@export_multiline var description: String = ""
# "" = always available. Otherwise, requires this god id to be unlocked.
@export var required_god_id: String = ""

@export_group("Base stats")
@export var base_damage: float = 10.0
@export var cooldown: float = 1.5
@export var base_area: float = 100.0
@export var base_projectile_count: int = 1
@export var base_projectile_speed: float = 400.0

@export_group("Per-level scaling (applied additively per level above 1)")
@export var damage_per_level: float = 2.0
@export var cooldown_reduction_per_level: float = 0.08
@export var area_per_level: float = 15.0
@export var projectile_count_per_level: int = 0

@export_group("Meta")
@export var max_level: int = 5
@export var icon: Texture2D

@export_group("V2 hooks (unused in v1)")
@export var fuses_with: Array[String] = []


func damage_at_level(lvl: int) -> float:
	return base_damage + damage_per_level * (lvl - 1)


func cooldown_at_level(lvl: int) -> float:
	return max(0.1, cooldown - cooldown_reduction_per_level * (lvl - 1))


func area_at_level(lvl: int) -> float:
	return base_area + area_per_level * (lvl - 1)


func projectile_count_at_level(lvl: int) -> int:
	return base_projectile_count + projectile_count_per_level * (lvl - 1)
