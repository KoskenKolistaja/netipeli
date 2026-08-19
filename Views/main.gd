extends Node

@export var game_scene : PackedScene




func start_game():
	if not multiplayer.is_server():
		return
	
	start_game_for_clients.rpc()




@rpc("authority","reliable","call_local")
func start_game_for_clients():
	for c in get_children():
		if c is MainMenu:
			c.queue_free()
	add_child(game_scene.instantiate())
