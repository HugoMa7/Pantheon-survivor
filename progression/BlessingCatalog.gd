class_name BlessingCatalog extends RefCounted

# Static catalog mapping god id -> list of Blessing resources.
# Blessings are drawn from the union of all unlocked gods' pools at each shrine.

static func for_god(god_id: String) -> Array:
	var out: Array = []
	match god_id:
		"hermes":
			out.append(_make("hermes_swiftness", "Hermes's Swiftness", "+8% Move Speed", "move_speed", 0.08))
			out.append(_make("mercurial_steps", "Mercurial Steps", "+20% Pickup Radius", "pickup_radius", 0.20))
			out.append(_make("messengers_pace", "Messenger's Pace", "+5% Attack Speed", "attack_speed", 0.05))
		"bragi":
			out.append(_make("bragis_gift", "Bragi's Gift", "+1 Luck", "luck", 1.0))
			out.append(_make("skalds_chant", "Skald's Chant", "+10% XP Gain", "xp_mult", 0.10, true))
			out.append(_make("golden_verse", "Golden Verse", "+15% Gold Drops", "gold_mult", 0.15, true))
		"bastet":
			out.append(_make("feline_grace", "Feline Grace", "+5% Crit Chance", "crit_chance", 0.05))
			out.append(_make("fierce_claws", "Fierce Claws", "+25% Crit Damage", "crit_damage", 0.25))
			out.append(_make("nights_vigil", "Night's Vigil", "+8% Damage", "damage", 0.08))
		"zeus":
			out.append(_make("thunderclap", "Thunderclap", "+12% Damage", "damage", 0.12))
			out.append(_make("stormborn", "Stormborn", "+10% Attack Speed", "attack_speed", 0.10))
			out.append(_make("kings_vigor", "King's Vigor", "+20 Max HP", "max_hp", 20.0))
		"thor":
			out.append(_make("thunder_gods_might", "Thunder God's Might", "+30 Max HP", "max_hp", 30.0))
			out.append(_make("forge_mead", "Forge Mead", "+0.5 HP Regen/s", "hp_regen", 0.5))
			out.append(_make("oath_iron", "Oath-Iron", "+3 Armor", "armor", 3.0))
		"anubis":
			out.append(_make("judges_accuracy", "Judge's Accuracy", "+1 Projectile Count", "projectile_count", 1.0))
			out.append(_make("dark_winds", "Dark Winds", "+15% Projectile Speed", "projectile_speed", 0.15))
			out.append(_make("soul_tax", "Soul Tax", "+5% Lifesteal", "lifesteal", 0.05, true))
	return out


static func _make(id: String, name: String, desc: String, stat_id: String, value: float, is_blessing: bool = false) -> Blessing:
	var b := Blessing.new()
	b.id = id
	b.display_name = name
	b.description = desc
	b.stat_id = stat_id
	b.value = value
	b.is_blessing_effect = is_blessing
	return b


static func draw_from_unlocked(unlocked: Array, count: int, rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var pool: Array = []
	for gid in unlocked:
		pool.append_array(for_god(str(gid)))
	pool.shuffle()
	var n: int = min(count, pool.size())
	return pool.slice(0, n)
