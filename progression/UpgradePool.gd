class_name UpgradePool extends RefCounted

# Generates the 3-card pool shown on level-up.
# Kept as a static helper so callers can request cards without holding state.
# v2 will weight rolls by rarity and Luck; v1 draws uniformly from available cards.

static func draw_cards(player, count: int = 3) -> Array:
	var available: Array = []
	available.append_array(_weapon_cards(player))
	available.append_array(_stat_cards())
	available.append_array(_blessing_cards(player))

	available.shuffle()
	var n: int = min(count, available.size())
	return available.slice(0, n)


static func _weapon_cards(player) -> Array:
	var cards: Array = []
	if not player or not player.has_method("get_weapon_inventory"):
		return cards
	var inv = player.get_weapon_inventory()

	# Upgrades for owned weapons below max level
	for weapon in inv.owned_weapons():
		var data: WeaponData = weapon.data
		if weapon.level >= data.max_level:
			continue
		var c := UpgradeCard.new()
		c.id = "upgrade_%s" % data.id
		c.display_name = "%s Lv %d" % [data.display_name, weapon.level + 1]
		c.description = "Improve your %s." % data.display_name
		c.type = UpgradeCard.Type.WEAPON_UPGRADE
		c.target_id = data.id
		c.rarity = UpgradeCard.Rarity.UNCOMMON
		cards.append(c)

	# Acquire cards for unowned weapons if slots remain
	if inv.slots_free() > 0:
		for wd in inv.available_unowned():
			var c := UpgradeCard.new()
			c.id = "acquire_%s" % wd.id
			c.display_name = wd.display_name
			c.description = wd.description
			c.type = UpgradeCard.Type.WEAPON_NEW
			c.target_id = wd.id
			c.rarity = UpgradeCard.Rarity.RARE
			cards.append(c)
	return cards


static func _stat_cards() -> Array:
	var defs := [
		{"id": "max_hp",           "name": "Vigor",          "desc": "+20 Max HP",                "value": 20.0},
		{"id": "move_speed",       "name": "Swiftness",      "desc": "+5% Move Speed",            "value": 0.05},
		{"id": "damage",           "name": "Might",          "desc": "+10% Damage",               "value": 0.10},
		{"id": "attack_speed",     "name": "Fervor",         "desc": "+8% Attack Speed",          "value": 0.08},
		{"id": "pickup_radius",    "name": "Magnetism",      "desc": "+15% Pickup Radius",        "value": 0.15},
		{"id": "armor",            "name": "Fortitude",      "desc": "+3 Armor",                  "value": 3.0},
		{"id": "hp_regen",         "name": "Recovery",       "desc": "+0.5 HP/s Regen",           "value": 0.5},
		{"id": "crit_chance",      "name": "Precision",      "desc": "+3% Crit Chance",           "value": 0.03},
		{"id": "crit_damage",      "name": "Savagery",       "desc": "+15% Crit Damage",          "value": 0.15},
		{"id": "projectile_count", "name": "Multishot",      "desc": "+1 Projectile Count",       "value": 1.0},
		{"id": "projectile_speed", "name": "Swift Shot",     "desc": "+15% Projectile Speed",     "value": 0.15},
		{"id": "luck",             "name": "Fortune",        "desc": "+1 Luck",                   "value": 1.0},
	]
	var cards: Array = []
	for d in defs:
		var c := UpgradeCard.new()
		c.id = "stat_%s" % d.id
		c.display_name = d.name
		c.description = d.desc
		c.type = UpgradeCard.Type.STAT
		c.target_id = d.id
		c.value = d.value
		c.rarity = UpgradeCard.Rarity.COMMON
		cards.append(c)
	return cards


static func _blessing_cards(_player) -> Array:
	var defs := [
		{"id": "lifesteal",          "name": "Vampirism",       "desc": "Heal for 1% of damage dealt.",   "value": 0.01},
		{"id": "thorns",             "name": "Thorns",          "desc": "Reflect 10% damage taken.",      "value": 0.10},
		{"id": "xp_mult",            "name": "Wisdom",          "desc": "+10% XP gain.",                  "value": 0.10},
		{"id": "gold_mult",          "name": "Greed",           "desc": "+15% Gold gain.",                "value": 0.15},
	]
	var cards: Array = []
	for d in defs:
		var c := UpgradeCard.new()
		c.id = "blessing_%s" % d.id
		c.display_name = d.name
		c.description = d.desc
		c.type = UpgradeCard.Type.BLESSING
		c.target_id = d.id
		c.value = d.value
		c.rarity = UpgradeCard.Rarity.UNCOMMON
		cards.append(c)
	return cards
