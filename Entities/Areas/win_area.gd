extends Area2D

signal player_finished(player_id)





func _on_body_entered(body):
	if body.is_in_group("player"):
		print("ENTERED")
		if body.player_id == multiplayer.get_unique_id():
			request_win_game.rpc_id(1,body.player_id)



@rpc("any_peer","reliable","call_local")
func request_win_game(player_id):
	player_finished.emit(player_id)
