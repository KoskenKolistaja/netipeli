extends Node
class_name SFXPool

var _players: Array[AudioStreamPlayer] = []
var _override_index: int = 0

func _ready() -> void:
	# Populate the array with all AudioStreamPlayer children
	for child in get_children():
		if child is AudioStreamPlayer:
			_players.append(child)
			
	if _players.size() == 0:
		push_warning("SFXPool: No AudioStreamPlayer children found!")

func play_sfx(audio_stream: AudioStream) -> void:
	if _players.is_empty():
		return

	# 1. Look for the first available (non-playing) audio player
	for player in _players:
		if not player.playing:
			_start_playback(player, audio_stream)
			return

	# 2. If all are playing, override using a Round-Robin approach
	var player_to_override = _players[_override_index]
	_start_playback(player_to_override, audio_stream)
	
	# Increment the override index and wrap around using modulo
	_override_index = (_override_index + 1) % _players.size()

func _start_playback(player: AudioStreamPlayer, stream: AudioStream) -> void:
	player.stream = stream
	player.play()
