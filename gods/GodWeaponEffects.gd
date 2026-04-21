class_name GodWeaponEffects extends RefCounted

# 36 effects, 6 per god.  Each entry has:
#   god           — god id string
#   display_name  — shown in UI
#   description   — generic text (use get_desc_level for scaled version)
#   values        — Array of [lv1, lv2, lv3] numeric params used by Weapon._fx_*

const CATALOG: Dictionary = {
	# ── Zeus (Greek – Damage) ──────────────────────────────────────────────────
	"zeus_chain": {
		"god": "zeus",
		"display_name": "Chain Lightning",
		"description": "Hits arc to 2 nearby enemies for X% damage.\n[40% / 55% / 70%]",
		"values": [0.40, 0.55, 0.70],
	},
	"zeus_overcharge": {
		"god": "zeus",
		"display_name": "Overcharge",
		"description": "Every 5th hit deals bonus damage.\n[×3 / ×4 / ×5]",
		"values": [3.0, 4.0, 5.0],
	},
	"zeus_thundercrash": {
		"god": "zeus",
		"display_name": "Thundercrash",
		"description": "On kill, AoE pulse in Xpx radius.\n[35 dmg 110px / 55 dmg 140px / 75 dmg 170px]",
		"values": [35.0, 55.0, 75.0],
	},
	"zeus_static": {
		"god": "zeus",
		"display_name": "Static Charge",
		"description": "Each hit deals X flat bonus damage.\n[10 / 16 / 22]",
		"values": [10.0, 16.0, 22.0],
	},
	"zeus_voltage": {
		"god": "zeus",
		"display_name": "Voltage Rush",
		"description": "Every kill charges next attack for X% bonus damage.\n[40% / 65% / 90%]",
		"values": [0.40, 0.65, 0.90],
	},
	"zeus_discharge": {
		"god": "zeus",
		"display_name": "Discharge",
		"description": "On kill, stun nearby enemies.\n[0.35s 110px / 0.55s 140px / 0.75s 170px]",
		"values": [0.35, 0.55, 0.75],
	},

	# ── Thor (Norse – Tank) ────────────────────────────────────────────────────
	"thor_knockback": {
		"god": "thor",
		"display_name": "Mjolnir Force",
		"description": "Hits launch enemies away by X px.\n[80 / 130 / 180]",
		"values": [80.0, 130.0, 180.0],
	},
	"thor_stun": {
		"god": "thor",
		"display_name": "Thunder Strike",
		"description": "25% chance to stun enemies on hit.\n[0.6s / 0.9s / 1.2s]",
		"values": [0.6, 0.9, 1.2],
	},
	"thor_cleave": {
		"god": "thor",
		"display_name": "Cleave",
		"description": "Hits splash 50% damage in X px radius.\n[80px / 110px / 140px]",
		"values": [80.0, 110.0, 140.0],
	},
	"thor_berserker": {
		"god": "thor",
		"display_name": "Berserker",
		"description": "Below 40% HP: deal X% bonus damage.\n[+30% / +55% / +80%]",
		"values": [0.30, 0.55, 0.80],
	},
	"thor_quake": {
		"god": "thor",
		"display_name": "Earthquake",
		"description": "On kill, push nearby enemies away.\n[120px / 160px / 200px radius]",
		"values": [120.0, 160.0, 200.0],
	},
	"thor_iron_skin": {
		"god": "thor",
		"display_name": "Iron Skin",
		"description": "On kill, gain +X armor (max 10 stacks).\n[+1 / +2 / +3]",
		"values": [1.0, 2.0, 3.0],
	},

	# ── Hermes (Greek – Speed) ─────────────────────────────────────────────────
	"hermes_swift": {
		"god": "hermes",
		"display_name": "Swift Kill",
		"description": "Killing an enemy resets this weapon's cooldown.\n[All levels]",
		"values": [1.0, 1.0, 1.0],
	},
	"hermes_fleet": {
		"god": "hermes",
		"display_name": "Fleet Foot",
		"description": "Each hit boosts move speed for 1.5s.\n[+12% / +18% / +25%]",
		"values": [0.12, 0.18, 0.25],
	},
	"hermes_phantom": {
		"god": "hermes",
		"display_name": "Phantom Strike",
		"description": "Chance to fire a second shot instantly.\n[20% / 30% / 40%]",
		"values": [0.20, 0.30, 0.40],
	},
	"hermes_dash": {
		"god": "hermes",
		"display_name": "Evasion",
		"description": "On kill, become invincible briefly.\n[0.3s / 0.5s / 0.8s]",
		"values": [0.3, 0.5, 0.8],
	},
	"hermes_quickfingers": {
		"god": "hermes",
		"display_name": "Quick Fingers",
		"description": "On kill, reduce all weapon cooldowns by X s.\n[0.8s / 1.2s / 1.8s]",
		"values": [0.8, 1.2, 1.8],
	},
	"hermes_slipstream": {
		"god": "hermes",
		"display_name": "Slipstream",
		"description": "Projectile speed increased by X%.\n[+25% / +40% / +55%]",
		"values": [0.25, 0.40, 0.55],
	},

	# ── Bragi (Norse – XP/Gold) ────────────────────────────────────────────────
	"bragi_echo": {
		"god": "bragi",
		"display_name": "Echo",
		"description": "30% chance on hit to repeat damage.\n[×1 / ×1.5 / ×2 echo damage]",
		"values": [1.0, 1.5, 2.0],
	},
	"bragi_resonance": {
		"god": "bragi",
		"display_name": "Resonance",
		"description": "Kills grant XP bonus for 2s.\n[+100% / +150% / +200%]",
		"values": [1.0, 1.5, 2.0],
	},
	"bragi_saga": {
		"god": "bragi",
		"display_name": "Saga",
		"description": "On kill, chain spirit to nearby enemies.\n[2 targets 20dmg / 3 targets 30dmg / 4 targets 40dmg]",
		"values": [20.0, 30.0, 40.0],
	},
	"bragi_chorus": {
		"god": "bragi",
		"display_name": "Chorus",
		"description": "On kill, AoE burst in 100px.\n[12 / 20 / 30 damage]",
		"values": [12.0, 20.0, 30.0],
	},
	"bragi_ballad": {
		"god": "bragi",
		"display_name": "Ballad",
		"description": "Chance on hit: +25% damage buff for 3s.\n[20% / 30% / 40% chance]",
		"values": [0.20, 0.30, 0.40],
	},
	"bragi_verse": {
		"god": "bragi",
		"display_name": "Verse",
		"description": "Chance to spawn an XP gem on hit.\n[5% / 8% / 12%]",
		"values": [0.05, 0.08, 0.12],
	},

	# ── Bastet (Egyptian – Crit) ───────────────────────────────────────────────
	"bastet_bleed": {
		"god": "bastet",
		"display_name": "Claw Bleed",
		"description": "Critical hits apply bleed for 3s.\n[8 / 12 / 18 dps]",
		"values": [8.0, 12.0, 18.0],
	},
	"bastet_prowl": {
		"god": "bastet",
		"display_name": "Prowl",
		"description": "Landing a crit guarantees the next attack is also a crit.\n[All levels]",
		"values": [1.0, 1.0, 1.0],
	},
	"bastet_mark": {
		"god": "bastet",
		"display_name": "Mark of Bastet",
		"description": "Hitting an enemy 3 times marks it for bonus damage.\n[+40% / +55% / +70%]",
		"values": [0.40, 0.55, 0.70],
	},
	"bastet_huntress": {
		"god": "bastet",
		"display_name": "Huntress",
		"description": "Critical hits deal bonus damage on top of crit multiplier.\n[+25% / +40% / +55%]",
		"values": [0.25, 0.40, 0.55],
	},
	"bastet_shred": {
		"god": "bastet",
		"display_name": "Armor Shred",
		"description": "After N crits on same target, it takes bonus damage.\n[3 crits +20% / 2 crits +32% / 1 crit +45%]",
		"values": [0.20, 0.32, 0.45],
	},
	"bastet_nine_lives": {
		"god": "bastet",
		"display_name": "Nine Lives",
		"description": "Survive lethal hits per run.\n[1 / 2 / 3 charges]",
		"values": [1.0, 2.0, 3.0],
	},

	# ── Anubis (Egyptian – Lifesteal/Projectile) ───────────────────────────────
	"anubis_drain": {
		"god": "anubis",
		"display_name": "Soul Drain",
		"description": "Every hit restores HP.\n[3 / 5 / 8 HP]",
		"values": [3.0, 5.0, 8.0],
	},
	"anubis_curse": {
		"god": "anubis",
		"display_name": "Curse",
		"description": "20% chance on hit to curse enemies.\nCursed: +[30% / 45% / 60%] damage taken for [4/5/6]s.",
		"values": [0.30, 0.45, 0.60],
	},
	"anubis_soul": {
		"god": "anubis",
		"display_name": "Soul Harvest",
		"description": "On kill, seeking spirit attacks nearest enemy.\n[30 / 50 / 75 damage]",
		"values": [30.0, 50.0, 75.0],
	},
	"anubis_decay": {
		"god": "anubis",
		"display_name": "Decay",
		"description": "Killing a cursed enemy spreads curse to nearby targets.\n[1 / 2 / 3 targets]",
		"values": [1.0, 2.0, 3.0],
	},
	"anubis_ritual": {
		"god": "anubis",
		"display_name": "Dark Ritual",
		"description": "Every N kills, heal HP.\n[15 kills 8hp / 12 kills 12hp / 9 kills 16hp]",
		"values": [8.0, 12.0, 16.0],
	},
	"anubis_judgement": {
		"god": "anubis",
		"display_name": "Judgement",
		"description": "Chance on kill: reduce all weapon CDs by 0.8s.\n[25% / 40% / 55%]",
		"values": [0.25, 0.40, 0.55],
	},
}


static func effects_for_god(god_id: String) -> Array[String]:
	var result: Array[String] = []
	for key: String in CATALOG:
		if CATALOG[key]["god"] == god_id:
			result.append(key)
	return result


static func get_display_name(effect_id: String) -> String:
	return CATALOG.get(effect_id, {}).get("display_name", effect_id)


static func get_description(effect_id: String) -> String:
	return CATALOG.get(effect_id, {}).get("description", "")


static func get_god_id(effect_id: String) -> String:
	return CATALOG.get(effect_id, {}).get("god", "")


static func get_value(effect_id: String, level: int) -> float:
	var entry: Dictionary = CATALOG.get(effect_id, {})
	var vals: Array = entry.get("values", [1.0, 1.0, 1.0])
	var idx: int = clamp(level - 1, 0, vals.size() - 1)
	return float(vals[idx])
