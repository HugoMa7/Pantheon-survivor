# God Weapon Effects — v1 Summary

Effects are applied to individual weapons at Altars of Gods. Each weapon tracks its own `god_effects: Array[String]`. Logic runs in `Weapon.apply_god_effects(enemy, dmg, was_crit)` after every hit.

---

## Zeus — Greek, Damage

| Effect ID | Name | Trigger | Behaviour | Notes |
|---|---|---|---|---|
| `zeus_chain` | Chain Lightning | Every hit | Arcs to up to 2 nearby enemies (≤150px) for 40% of original damage | No visual yet — needs drawn arc |
| `zeus_overcharge` | Overcharge | Every 5th hit | Deals an extra 2× damage to the same target (total 3×) | Counter resets on kill or 5th hit |
| `zeus_thundercrash` | Thundercrash | On kill | AoE pulse, 35 flat dmg to all enemies within 110px | No visual yet — needs pulse ring |

---

## Thor — Norse, Tank

| Effect ID | Name | Trigger | Behaviour | Notes |
|---|---|---|---|---|
| `thor_knockback` | Mjolnir Force | Every hit | Pushes enemy 80px directly away from the weapon | Position teleport, not physics velocity |
| `thor_stun` | Thunder Strike | Every hit (25% chance) | Freezes enemy movement for 0.6s | Stacks duration with whichever is longer |
| `thor_cleave` | Cleave | Every hit | 50% splash damage to all enemies within 80px of the target | Can trigger chains with zeus_chain |

---

## Hermes — Greek, Speed

| Effect ID | Name | Trigger | Behaviour | Notes |
|---|---|---|---|---|
| `hermes_swift` | Swift Kill | On kill | Resets this weapon's cooldown to 0 immediately | Calls `_reset_cooldown()` — all weapons implement it |
| `hermes_fleet` | Fleet Foot | Every hit | +12% move speed for 1.5s, non-stacking (refreshes) | Uses `StatBlock.move_speed_mult`; reverts via timer |
| `hermes_phantom` | Phantom Strike | On fire (20% chance) | Fires a second copy of the attack for free | **Implemented for all weapons** via `should_phantom()` check at fire time |

---

## Bragi — Norse, XP/Gold

| Effect ID | Name | Trigger | Behaviour | Notes |
|---|---|---|---|---|
| `bragi_echo` | Echo | Every hit (30% chance) | Deals the same damage a second time to the same enemy | Skipped if enemy is already dead |
| `bragi_resonance` | Resonance | On kill | Boosts player `xp_mult` by +1.0 for 2s | Uses `StatBlock.xp_mult`; reverts via timer |
| `bragi_saga` | Saga | On kill | Spawns a homing projectile (pierce 1) at kill pos — chains to 2 enemies for 20 dmg | Blue tint projectile, 4s lifetime |

---

## Bastet — Egyptian, Crit

| Effect ID | Name | Trigger | Behaviour | Notes |
|---|---|---|---|---|
| `bastet_bleed` | Claw Bleed | On crit hit | Applies bleed: 8 dmg/s for 3s on the hit enemy | Uses `Enemy.apply_bleed()` |
| `bastet_prowl` | Prowl | On crit hit | Sets `_forced_crit = true` — next attack guaranteed crit | Consumed on next `roll_crit()` call |
| `bastet_mark` | Mark of Bastet | Every hit | Increments enemy's mark counter; at 3+ marks enemy takes +40% damage | Tracked on enemy via `_mark_hits` |

---

## Anubis — Egyptian, Lifesteal/Projectile

| Effect ID | Name | Trigger | Behaviour | Notes |
|---|---|---|---|---|
| `anubis_drain` | Soul Drain | Every hit | Restores 3 HP to the player | Calls `Player.heal(3)` |
| `anubis_curse` | Curse | Every hit (20% chance) | Cursed enemies take +30% damage for 4s | Uses `Enemy.apply_curse()`; curse timer is refreshed, not stacked |
| `anubis_soul` | Soul Harvest | On kill | Spawns a homing seeking projectile at kill pos, 30 dmg, no pierce | Purple tint projectile, 3s lifetime |

---

## Known Issues / TODO

- **Visuals missing**: `zeus_chain`, `zeus_thundercrash` have no drawn effects yet. Need temporary line/ring visuals.
- **Bastet mark indicator**: No visual feedback on enemies that are marked (≥3 hits). A color tint on the enemy sprite would help.
- **Curse/bleed/stun visual**: No status indicators on enemies.
- **`bragi_resonance`**: Timer-based `xp_mult` mutation. If the player dies or the scene changes mid-timer, the stat may not revert (harmless since runs end, but worth noting).
- **`hermes_fleet` stack prevention**: Uses `_speed_boost_active` bool — the boost refreshes to 1.5s without stacking. Multiple hits during the window are ignored.
- **Effect uniqueness**: Applying the same effect twice to the same weapon is blocked in `AltarScreen`. If somehow circumvented, effects could double-apply (e.g. double echo, double drain). Guard exists in UI only.
- **Cyclops boss**: Final boss does NOT drop an altar (correct by design — only elite Cyclops drop altars).

---

## Spawn Rules

| Source | Chance | Location |
|---|---|---|
| Elite Cyclops death | 100% | ~40px left of death position |
| EventDirector random roll | 12% every 120s | Random offset from player (260–420px) |
