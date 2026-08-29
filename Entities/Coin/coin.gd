extends Node2D





func _on_area_2d_body_entered(body):
	if not multiplayer.is_server():
		return
	
	
	if body.is_in_group("player"):
		MetaData.player_change_coin(1,body.player_id)
		
		
		queue_free()
