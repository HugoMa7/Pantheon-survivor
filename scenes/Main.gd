extends Node2D

const VICTORY_SCREEN := preload("res://ui/Victory.tscn")
const GAME_OVER_SCREEN := preload("res://ui/GameOver.tscn")

@onready var player: Player = $Player
@onready var hud: CanvasLayer = $HUD
@onready var wave_director: WaveDirector = $WaveDirector
@onready var event_director: EventDirector = $EventDirector

var _run_ended: bool = false


func _ready() -> void:
	if hud.has_method("bind_player"):
		hud.bind_player(player)

	_apply_selected_god()
	_apply_selected_trinket()
	_grant_starting_weapon()

	var weapon_panel: CanvasLayer = load("res://ui/WeaponStatsPanel.gd").new()
	add_child(weapon_panel)
	weapon_panel.bind_player(player)

	if SaveGame.debug_mode:
		add_child(load("res://ui/DebugPanel.gd").new())

	player.died.connect(_on_player_died)
	event_director.final_boss_slain.connect(_on_final_boss_slain)


func _apply_selected_god() -> void:
	pass


func _apply_selected_trinket() -> void:
	if SaveGame.selected_trinket == "":
		return
	var t := TrinketCatalog.get_trinket(SaveGame.selected_trinket)
	if t == null:
		return
	player.apply_trinket(t)
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Trinket: %s" % t.display_name, 2.5)


func _grant_starting_weapon() -> void:
	var weapon_id: String = SaveGame.selected_weapon
	if weapon_id == "" or not Player.WEAPON_REGISTRY.has(weapon_id):
		weapon_id = "divine_flame"
	var weapons_node: Node = player.get_node("Weapons")
	for child in weapons_node.get_children():
		if child is Weapon:
			weapons_node.remove_child(child)
			child.queue_free()
	player.add_weapon(weapon_id)


func _on_player_died() -> void:
	if _run_ended:
		return
	_run_ended = true
	# Persist earned gold
	SaveGame.add_gold(player.gold)
	var screen: GameOverScreen = GAME_OVER_SCREEN.instantiate()
	add_child(screen)
	screen.show_stats(hud.get_elapsed() if hud.has_method("get_elapsed") else 0.0, player.level, player.gold)


func _on_final_boss_slain(_pos: Vector2) -> void:
	if _run_ended:
		return
	_run_ended = true
	# Let the boss gold pile magnetize and be collected before showing the screen.
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	SaveGame.add_gold(player.gold)
	var screen: VictoryScreen = VICTORY_SCREEN.instantiate()
	add_child(screen)
	screen.show_stats(hud.get_elapsed() if hud.has_method("get_elapsed") else 0.0, player.level, player.gold)
