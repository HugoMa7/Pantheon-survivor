extends Node

# Audio stub autoload. Real SFX/music are a polish pass; this keeps the API
# in place so gameplay scripts can call `AudioManager.play("sfx_id")` today
# and have sounds swapped in later without edits to callers.

const SOUND_LIBRARY: Dictionary = {
	# "weapon_flame": preload("res://assets/audio/flame.wav"),
	# "level_up": preload("res://assets/audio/level_up.wav"),
	# "shrine_pray": preload("res://assets/audio/shrine.wav"),
	# "gold_pickup": preload("res://assets/audio/coin.wav"),
	# "relic_chest": preload("res://assets/audio/chest.wav"),
	# "elite_spawn": preload("res://assets/audio/elite_horn.wav"),
	# "boss_spawn": preload("res://assets/audio/boss_roar.wav"),
	# "victory": preload("res://assets/audio/victory.wav"),
	# "game_over": preload("res://assets/audio/game_over.wav"),
}

var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(id: String, volume_db: float = 0.0) -> void:
	if not SOUND_LIBRARY.has(id):
		return
	var stream: AudioStream = SOUND_LIBRARY[id]
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# All players busy — drop the sound rather than queue.
