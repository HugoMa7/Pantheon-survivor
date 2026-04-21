---
description: Godot 2D game development expert for the Pantheon project. Use when working on any GDScript, scenes, systems, or game logic.
---

You are working on **Pantheon**, a 2D horde-survival roguelike. Always read `agent.md` at the project root before doing any work. Update it after structural changes.

## Project Stack
- Godot 4.6, GDScript, GL Compatibility renderer
- 1280×720 viewport, 144 FPS cap
- Autoloads: `InputController`, `SaveGame`, `AudioManager`
- Physics layers: world(1), player(2), enemy(3), pickup(4), player_projectile(5), enemy_projectile(6)

## GDScript Rules

**Syntax & style**
- Use `@export` for designer-tunable values, never hardcode them inside logic
- Use `@onready` instead of assigning nodes in `_ready()`
- Prefer `signal` declarations at the top of the class, before vars
- Use typed variables: `var speed: float = 220.0` not `var speed = 220`
- Use `StringName` (&"name") for signal/group/method name lookups in hot paths
- Avoid `get_node()` in `_process()` — cache refs in `_ready()`
- Use `_physics_process()` for movement/collision, `_process()` for visuals/timers
- Use `await` over manual state flags for one-shot async sequences

**Node patterns**
- Keep scene roots as plain `Node2D`/`Control` — put logic in the script, not in children
- Use `add_to_group()` + `get_tree().get_nodes_in_group()` for loose coupling (e.g. enemies, pickups)
- Prefer signals over direct node references across scenes to avoid tight coupling
- `queue_free()` not `free()` — always defer deletion to end of frame
- For pooling: disable/hide nodes instead of freeing; re-enable on reuse

**Signals**
- Declare all signals at class top
- Connect in `_ready()` using `signal_name.connect(callable)` syntax (not legacy `connect("name", ...)`)
- Emit with `signal_name.emit(args)` not `emit_signal("name", args)`

**Resources (.tres)**
- Data goes in Resource subclasses, not in node scripts
- `@export` resource fields in node scripts; fill in the Inspector
- Never load resources inside `_process()` — preload at class level or `_ready()`

**Performance**
- Cap enemy count (WaveDirector already does 400 max) — never iterate unbounded arrays per frame
- Use `Area2D` + `monitoring = false` when not actively detecting, flip on when needed
- Avoid `find_child()` / `find_node()` at runtime — store refs
- Lerp-based smoothing: `lerp(current, target, delta * speed)` not raw assignment

## This Project's Patterns

**StatBlock (data/StatBlock.gd)**
- All player modifiers live here as additive floats
- Compose via `effective_*()` methods on Player, never inline the math elsewhere
- Adding a new stat: add field to StatBlock → add `effective_*()` to Player → wire into apply_card() and relevant weapons/blessings

**Weapon system**
- Extend `Weapon` (weapons/Weapon.gd), implement `_process()`
- Register new weapon in Player.WEAPON_REGISTRY dict
- Create `.tres` WeaponData resource for config
- Weapon scaling: use `current_level` and the base data fields — don't hardcode level thresholds

**Adding a new enemy**
- Create folder under `enemies/`, extend `Enemy`
- Add `.tres` EnemyData resource for HP, damage, speed, gold_drop_chance
- Register spawn in WaveDirector if it should appear in waves

**Adding a new god**
- Create `.tres` GodData (name, pantheon, starting_stat, signature_weapon, blessing_keys)
- Add to GodCatalog
- Add blessings to BlessingCatalog under that god's key
- Default-locked → unlock via HiddenAltar if desired

**Adding a trinket**
- Create `.tres` Trinket resource
- Add to TrinketCatalog
- Apply effect in Player.apply_trinket() (or via StatBlock if it's a stat modifier)

**UI flow**
- Game-blocking UI (level-up, shrine) should pause the scene tree: `get_tree().paused = true`
- Resume in the screen's close/confirm callback
- HUD toasts: call `HUD.show_toast(text)` — don't add new Label nodes ad hoc

**Save system**
- All persistent data lives in SaveGame (autoload)
- Read: `SaveGame.unlocked_gods`, `.unlocked_trinkets`, `.gold`, `.weapon_slots`, `.selected_god`, `.selected_trinket`
- Always call `SaveGame.save()` after mutating persistent state

## Common Gotchas

- `CharacterBody2D.move_and_slide()` returns void in Godot 4 — velocity is on `.velocity` property
- `delta` in `_physics_process` is fixed (1/physics_fps), not variable like `_process`
- Signals from freed nodes can still fire this frame — guard with `is_instance_valid(node)`
- `preload()` runs at parse time; use `load()` inside functions if the path is dynamic
- `.tscn` scene instantiation: `scene.instantiate()` not `scene.instance()` (Godot 3 API)
- `Area2D` overlap detection requires BOTH bodies to have matching layer/mask bits set
- `@tool` at top of script makes it run in editor — only use when intentional

## Debugging Checklist

1. Node not found → check `@onready` path matches actual scene tree
2. Signal not firing → verify `.connect()` was called AND emitter is in the tree
3. No collision → check physics layer AND mask on both bodies
4. `queue_free` crash → use `is_instance_valid()` before accessing freed refs
5. Export var not showing → ensure script is saved and class_name matches
6. Physics jitter → make sure movement is in `_physics_process`, not `_process`
