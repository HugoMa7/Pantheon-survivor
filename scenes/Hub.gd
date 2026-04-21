extends Control

# Between-run meta-progression hub.
# v1 purchases: weapon slot expansion. Future: starting HP / move-speed / new chars / new maps.

@onready var gold_label: Label = %GoldLabel
@onready var slot_label: Label = %SlotLabel
@onready var buy_slot_btn: Button = %BuySlotButton
@onready var start_run_btn: Button = %StartRunButton
@onready var main_menu_btn: Button = %MainMenuButton
@onready var feedback_label: Label = %FeedbackLabel


func _ready() -> void:
	buy_slot_btn.pressed.connect(_on_buy_slot)
	start_run_btn.pressed.connect(_on_start_run)
	main_menu_btn.pressed.connect(_on_main_menu)
	_refresh()


func _refresh() -> void:
	gold_label.text = "Gold: %d" % SaveGame.gold
	slot_label.text = "Weapon slots: %d / %d" % [SaveGame.weapon_slots, SaveGame.MAX_WEAPON_SLOTS]
	var cost := SaveGame.next_slot_cost()
	if cost <= 0:
		buy_slot_btn.text = "Max slots reached"
		buy_slot_btn.disabled = true
	else:
		buy_slot_btn.text = "Buy next slot (%d gold)" % cost
		buy_slot_btn.disabled = SaveGame.gold < cost


func _on_buy_slot() -> void:
	if SaveGame.buy_next_weapon_slot():
		feedback_label.text = "Slot purchased. The gods approve."
	else:
		feedback_label.text = "Not enough gold."
	_refresh()


func _on_start_run() -> void:
	get_tree().change_scene_to_file("res://ui/PreRunGodPick.tscn")


func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
