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

	player.died.connect(_on_player_died)
	event_director.final_boss_slain.connect(_on_final_boss_slain)


func _apply_selected_god() -> void:
	var god := GodCatalog.get_god(SaveGame.selected_god)
	if god == null:
		return
	if god.starting_stat_id != "":
		player._apply_stat(god.starting_stat_id, god.starting_stat_value)
	# _apply_stat already bumps current_hp when stat_id is "max_hp"; just clamp and rebroadcast.
	player.current_hp = min(player.current_hp, player.effective_max_hp())
	player.health_changed.emit(player.current_hp, player.effective_max_hp())
	if hud and hud.has_method("show_toast"):
		hud.show_toast("%s walks with you." % god.display_name, 2.5)


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
	var god := GodCatalog.get_god(SaveGame.selected_god)
	var weapon_id: String = ""
	if god and god.signature_weapon_id != "":
		weapon_id = god.signature_weapon_id
	else:
		weapon_id = "divine_flame"
	# Clear any scene-baked starter weapons so we don't double-equip
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
