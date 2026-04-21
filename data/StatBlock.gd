class_name StatBlock extends Resource

# Additive bonuses applied on top of base stats.

@export var max_hp_bonus: float = 0.0
@export var hp_regen: float = 0.0
@export var shield: float = 0.0
@export var armor: float = 0.0
@export var move_speed_mult: float = 0.0      # 0.1 = +10%
@export var damage_mult: float = 0.0           # 0.1 = +10%
@export var attack_speed_mult: float = 0.0     # 0.1 = -10% cooldown
@export var crit_chance: float = 0.0           # 0.1 = +10%
@export var crit_damage_mult: float = 0.5      # +50% base on crit
@export var projectile_count_bonus: int = 0
@export var projectile_speed_mult: float = 0.0
@export var pickup_radius_mult: float = 0.0
@export var luck: int = 0
@export var xp_mult: float = 0.0
@export var gold_mult: float = 0.0

# Blessings
@export var lifesteal: float = 0.0
@export var thorns: float = 0.0

# Trinket-driven downsides (e.g. Ares's Locket: +10% damage taken)
@export var damage_taken_mult: float = 0.0
