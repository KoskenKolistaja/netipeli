extends Node

@export var game_scene : PackedScene





func start_game():
	if not multiplayer.is_server():
		return
	
	start_game_for_clients.rpc()
	
	sync_player_colors.rpc(PlayerData.player_colors)



@rpc("authority","reliable","call_local")
func start_game_for_clients():
	for c in get_children():
		if c is MainMenu:
			c.queue_free()
	add_child(game_scene.instantiate())


@rpc("authority","reliable")
func sync_player_colors(new_colors):
	PlayerData.update_colors(new_colors)
