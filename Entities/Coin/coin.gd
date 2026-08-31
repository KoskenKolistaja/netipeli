extends Node2D


@export var coin_sound : AudioStream


func _on_area_2d_body_entered(body):
	
	if body.player_id == multiplayer.get_unique_id():
		Audio.play_sfx(coin_sound)
	
	if not multiplayer.is_server():
		return
	
	
	if body.is_in_group("player"):
		MetaData.player_change_coin(1,body.player_id)
		
		
		queue_free()
