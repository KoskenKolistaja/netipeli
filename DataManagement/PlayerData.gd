extends Node

# Local player's own profile info
var player_name: String = ""

# Dictionary holding all connected players: { peer_id (int): player_name (String) }
var players: Dictionary = {}

## Adds or updates a player in the session dictionary
func add_player(id: int, name: String) -> void:
	players[id] = name

## Removes a player when they disconnect
func remove_player(id: int) -> void:
	players.erase(id)

## Clears all players on disconnect
func clear_players() -> void:
	players.clear()

## Helper to get a player's name by unique network ID
func get_player_name(id: int) -> String:
	return players.get(id, "Unknown Player")
