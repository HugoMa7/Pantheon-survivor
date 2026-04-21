class_name UpgradeCard extends Resource

enum Type { WEAPON_NEW, WEAPON_UPGRADE, STAT, BLESSING }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var type: Type = Type.STAT
@export var rarity: Rarity = Rarity.COMMON

# target_id meaning depends on type:
#   WEAPON_NEW / WEAPON_UPGRADE -> weapon id
#   STAT -> stat key in StatBlock (or "max_hp", "move_speed", etc.)
#   BLESSING -> blessing key
@export var target_id: String = ""
@export var value: float = 0.0
@export var icon: Texture2D

static func rarity_color(r: int) -> Color:
	match r:
		Rarity.COMMON: return Color(0.75, 0.75, 0.75)
		Rarity.UNCOMMON: return Color(0.35, 0.85, 0.35)
		Rarity.RARE: return Color(0.35, 0.55, 1.0)
		Rarity.EPIC: return Color(0.75, 0.35, 1.0)
		Rarity.LEGENDARY: return Color(1.0, 0.6, 0.15)
	return Color.WHITE
