# Pantheon — Project Context

> Read this before touching anything. Update it when you change systems, add files, or alter architecture.

---

## What This Is

**Pantheon** is a 2D horde-survival roguelike built in **Godot 4.6 (GDScript)**. Defend Olympus against endless enemy waves, collect upgrades, survive elite encounters, and beat the final boss. Inspired by Hades + Vampire Survivors. Prototype/early-dev stage — placeholder visuals, stubbed audio.

---

## Tech Stack

| Thing | Detail |
|---|---|
| Engine | Godot 4.6, GL Compatibility renderer |
| Language | GDScript (50 scripts) |
| Viewport | 1280×720, expandable |
| Max FPS | 144 |
| Renderer | 2D with 6 physics layers |
| Physics Layers | world, player, enemy, pickup, player_projectile, enemy_projectile |
| Persistence | ConfigFile via SaveGame autoload |
| Audio | Stubbed (AudioManager API ready, no real SFX files yet) |

---

## Project Structure

```
Pantheon-survivor-main/
├── audio/            AudioManager.gd — audio pool stub
├── data/             StatBlock.gd — player stat/modifier data class
├── enemies/          Enemy base, EnemyData, EnemyQuery, EnemyProjectile
│   ├── cyclops/      Elite + boss enemy (ranged+melee AI, gold drops)
│   └── shade/        Basic horde melee enemy
├── events/           Timed world events
│   EventDirector.gd  — drives shrines, elite portals, final boss clock
│   ElitePortal.gd    — spawns Cyclops + shade escorts
│   Shrine.gd         — interactable divine shrine (E to bless)
│   HiddenAltar.gd    — rare altar that unlocks a god
├── gods/             God definitions + catalog
│   GodCatalog.gd     — static god registry
│   GodData.gd        — god definition (starting buff, weapon, pantheon)
│   hermes/bragi/bastet/zeus/thor/anubis .tres
├── maps/             DefendOlympus.tscn — main game level
│   MarbleGround.gd   — procedural marble floor
├── pickups/          XPGem, GoldCoin, RelicChest (auto-magnetize)
├── player/           Player.gd, InputController.gd, Player.tscn
├── progression/      SaveGame, WaveDirector, UpgradeCard, UpgradePool,
│                     Blessing, BlessingCatalog
├── scenes/           Main.gd/tscn, MainMenu, Hub
├── trinkets/         Trinket.gd, TrinketCatalog.gd + 6 .tres items
├── ui/               HUD, LevelUpScreen, GameOver, Victory, PauseMenu,
│                     PreRunGodPick, PreRunTrinketPick, ShrineScreen, Settings
└── weapons/          Weapon.gd base, WeaponData.gd, Projectile
    ├── flame/        Divine Flame — AoE pulse
    ├── bow/          Hunter's Bow — projectiles
    ├── shield/       Spinning Shield — melee AoE orbit
    ├── bolt/         Zeus Bolt — lightning strike
    ├── mjolnir/      Mjolnir — thrown hammer
    └── scarabs/      Scarab Swarm — summoned minions
```

---

## Autoloads (Singletons)

| Name | File | Purpose |
|---|---|---|
| `InputController` | player/InputController.gd | Polls WASD/arrows/E/ESC |
| `SaveGame` | progression/SaveGame.gd | Persistent meta-progression via ConfigFile |
| `AudioManager` | audio/AudioManager.gd | Audio API stub |

---

## Scene Flow

```
MainMenu.tscn
  → PreRunGodPick.tscn    (repurposed: weapon picker, sets SaveGame.selected_weapon)
  → PreRunTrinketPick.tscn (sets SaveGame.selected_trinket)
  → Main.tscn             (gameplay)
      ├── DefendOlympus (map)
      ├── Player (init'd with god + trinket + weapon)
      ├── WaveDirector (spawns shades)
      ├── EventDirector (shrine/elite/boss clock)
      ├── HUD
      ├── LevelUpScreen (overlays on level-up)
      └── PauseMenu
  → GameOver.tscn  (on Player.died)
  → Victory.tscn   (on EventDirector.final_boss_slain)
```

---

## Core Systems

### Player (player/Player.gd)

- **Stats**: `StatBlock` holds additive multipliers — `damage_mult`, `move_speed_mult`, `armor`, `crit_chance`, `lifesteal`, `pickup_radius_mult`, `xp_mult`, `gold_mult`, `damage_taken_mult`, `max_hp_bonus`
- **Effective values**: `effective_max_hp()`, `effective_move_speed()`, etc. apply mults to base
- **Base move speed**: 220 px/s
- **Base HP**: 100
- **Weapons**: array, max 3–6 slots (upgradeable via SaveGame.weapon_slots)
- **XP threshold**: `~5 * level^1.35`
- **Level-up**: emits `leveled_up` → LevelUpScreen shows 3 cards → `apply_card()` dispatches result
- **Weapon registry**: hardcoded dict in Player (v2 will be data-driven)

### Weapon System (weapons/Weapon.gd)

- Each weapon extends `Weapon`, implements `_process()` firing logic
- Stats scale per level: damage, cooldown, area, projectile count
- Player's `damage_mult`, `crit_chance`, `attack_speed_mult` applied at fire time
- 6 weapons: divine_flame, hunters_bow, spinning_shield, zeus_bolt, mjolnir, scarab_swarm

### Enemy Spawning (progression/WaveDirector.gd)

Smooth difficulty lerp over 30-min run (elapsed / 1800):

| Stat | Min | Max |
|---|---|---|
| HP mult | 1× | 20× |
| Damage mult | 1× | 4× |
| Spawn interval | 1.5s | 0.15s |
| Burst count | 1 | 5 |

- Max 400 alive at once
- Spawns at 520px radius around player
- Deaths drop XP gems + chance gold

### Event Timeline (events/EventDirector.gd)

| Time | Event |
|---|---|
| ~45s | First shrine |
| Every ~90s | Divine shrine (15% + luck chance of Hidden Altar) |
| 10:00 | Elite Cyclops portal + shade escorts |
| 20:00 | Second elite portal |
| 30:00 | Final boss (Elder Cyclops) → victory on death |

### Progression / Cards (progression/UpgradePool.gd)

Three card types drawn on level-up:

| Type | Effect |
|---|---|
| `WEAPON_NEW` | Add unowned weapon (if slot available) |
| `WEAPON_UPGRADE` | +1 level on owned weapon (capped at max_level) |
| `STAT` | +max HP, +speed%, +damage%, +armor, +crit, +pickup radius, +XP/gold mult |
| `BLESSING` | Lifesteal%, thorns reflect, XP/gold mult, damage taken mod |

### Meta-Progression (progression/SaveGame.gd, persistent)

- Unlocked gods (default: hermes, bragi, bastet; zeus/thor/anubis via Hidden Altar)
- Unlocked trinkets (6 total, via RelicChest drops from elites)
- Accumulated gold (spent in Hub)
- Hub upgrades: weapon slots 3→4 (100g), 4→5 (200g), 5→6 (400g)
- Selected god/trinket for next run

### Debug Panel (ui/DebugPanel.gd)

- **F1** toggles the overlay during any run (CanvasLayer 100, PROCESS_MODE_ALWAYS)
- Spawn buttons: Altar, Chest, Elite — call `EventDirector.spawn_*_now()` (group: `event_director`)
- Kill All: sets all enemies' HP to 0 via `take_damage`
- Density OptionButton: sets `WaveDirector.debug_density_mult` (0.25× → 8×); scales both spawn interval and burst count
- God Mode checkbox: sets `Player.debug_god_mode = true` — bypasses all `take_damage`
- +1000 XP / +100 Gold / Full Heal / +1 Level buttons
- No .tscn needed — instantiated in `Main._ready()` with `load().new()`

### Altar of Gods (events/AltarOfGods.gd)

- Interactable Area2D (press E) — 2-phase modal via `ui/AltarScreen.gd`
- Phase 1: pick 1 of 3 random gods → calls `SaveGame.record_god_interaction(god_id)` (unlocks god + records in `interacted_gods`)
- Phase 2: pick 1 of 3 weapon upgrades (one per effect from the god's pool, paired to an equipped weapon)
- Upgrades stored as `weapon.god_effects: Array[String]`; dispatched in `Weapon.apply_god_effects(enemy, dmg, was_crit)`
- **Spawns**: elite Cyclops death (100%), EventDirector random roll (12% every 120s)
- Effect catalog: `gods/GodWeaponEffects.gd` — **36 effects, 6 per god**
- `god_effects: Dictionary` on Weapon (effect_id → level int 1–3). Repicking increments level (max 3).
- `GodWeaponEffects.get_value(effect_id, level)` returns per-level float value
- AltarScreen: reroll button (3 base rerolls), level-up detection shows "[Lv1 → Lv2]" in upgrade cards
- Enemy status effects: `apply_stun()`, `apply_bleed()`, `apply_curse(dur, bonus)`, `apply_mark(bonus)`, `apply_shred(bonus)`, `is_cursed()`
- `Player.take_damage` checks `_invincibility_timer` and `_consume_nine_lives()`
- `Player.grant_invincibility(duration)` added; `_consume_nine_lives()` iterates weapons for nine_lives_charges
- `Weapon.reduce_cooldown(amount)` base + overrides in all 5 cd-based weapons
- WeaponStatsPanel shows "⚡ Effect Lv2" with level in tooltip

### Pickup Magnetization

- `XPGem` / `GoldCoin`: auto-attract when player within `pickup_radius` (90 × (1 + pickup_radius_mult))
- `RelicChest`: dropped by elites, press E to unlock a trinket

### Blessing System (progression/BlessingCatalog.gd)

- Each god has a pool of blessings
- Shrine draws 3 random blessings from union of all **unlocked** gods' pools
- Luck stat scales Hidden Altar appearance chance

---

## Gods

| God | Pantheon | Focus |
|---|---|---|
| Hermes | Greek | Speed |
| Bragi | Norse | XP / Gold |
| Bastet | Egyptian | Crit |
| Zeus | Greek | Damage (locked) |
| Thor | Norse | Tank (locked) |
| Anubis | Egyptian | Projectile / Lifesteal (locked) |

---

## Trinkets (6 total)

hermes_sandal, thors_belt, atlas_shoulder, ares_locket, fortuna_coin, hades_obol — all unlocked via RelicChest drops mid-run.

---

## Damage Formula

```
# Outgoing (weapon hit)
damage = weapon_damage * (1 + player.stat_block.damage_mult) * crit_multiplier

# Incoming (player takes hit)
net = gross_damage * (1 + stat_block.damage_taken_mult) - stat_block.armor
```

---

## Known Gaps / v1 Limitations

- **Audio**: No actual SFX/music files. AudioManager API is placeholder.
- **Visuals**: All procedural placeholder art. No sprite assets yet.
- **Weapon registry**: Hardcoded in Player.gd — v2 comment says it'll be data-driven.
- **Unused fields**: `GodData.weapon_effect_modifiers` and `WeaponData.fuses_with` — hooks for v2 god-specific upgrades and weapon fusion.
- **Luck stat**: BlessingCatalog references it but implementation is partial.
- **No animation system**: Characters are colored shapes.

---

## v2 Hooks (noted in code comments)

- God-specific weapon upgrade paths (weapon_effect_modifiers)
- Weapon fusion (fuses_with)
- Rarity-weighted card draws
- Luck scaling on blessings
- Data-driven weapon registry
- Real audio pass

---

## Architectural Patterns

1. **Autoload singletons** for global state (InputController, SaveGame, AudioManager)
2. **Signal-driven events** — Player emits `leveled_up`, `health_changed`, `died`; Main listens
3. **Static catalogs** (GodCatalog, TrinketCatalog, BlessingCatalog) as RefCounted singletons
4. **Resource-driven config** — all game data in .tres files, not hardcoded logic
5. **StatBlock multiplier architecture** — `effective_*()` methods compose base + mults
6. **Generalized card system** — all upgrades flow through `UpgradeCard` → `apply_card()`
7. **Lerp-based difficulty** — WaveDirector uses `elapsed/run_duration` for smooth curve

---

## Key File Quick-Ref

| What you're looking for | File |
|---|---|
| Game init + win/lose signals | scenes/Main.gd |
| Player stats, movement, level-up | player/Player.gd |
| Enemy wave spawning | progression/WaveDirector.gd |
| Shrine / elite / boss timing | events/EventDirector.gd |
| Weapon base class | weapons/Weapon.gd |
| Enemy base AI | enemies/Enemy.gd |
| Boss AI | enemies/cyclops/Cyclops.gd |
| Persistent save data | progression/SaveGame.gd |
| Card pool generation | progression/UpgradePool.gd |
| God blessing pools | progression/BlessingCatalog.gd |
| HUD | ui/HUD.gd |
| Level-up card UI | ui/LevelUpScreen.gd |
