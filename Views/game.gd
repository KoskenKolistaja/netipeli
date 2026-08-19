extends Node2D

#17,9

var block_index = 0

@export var block_scene : PackedScene
@export var player_scene : PackedScene

var block_list : Array = []

var origin_position = Vector2(32,608) 

var players_to_confirm = []

var players_to_spawn = []

var players_ready = []

var round_won = false

func _ready():
	%WinArea.player_finished.connect(on_player_finished)
	
	if not multiplayer.is_server():
		await get_tree().create_timer(0.1).timeout
		confirm_player.rpc_id(1,multiplayer.get_unique_id())
	else:
		print("PLAYERS TO CONFIRM: " + str(players_to_confirm))
		for key in PlayerData.players.keys():
			players_to_spawn.append(key)
			if key == 1:
				continue
			else:
				players_to_confirm.append(key)
	

func on_player_finished(player_id):
	if round_won:
		return
	
	print("PLAYER " + str(player_id) + " WON!" )
	game_over.rpc(player_id)
	for p_id in PlayerData.players.keys():
		players_ready.append(p_id)
	
	for p_id in PlayerData.players.keys():
		players_to_confirm.append(p_id)

@rpc("authority","reliable","call_local")
func game_over(player_id):
	%GameOverScreen.show()
	%ReadyCheckBox.set_pressed_no_signal(false)
	%WinnerTextLabel.text = PlayerData.players[player_id] + " won the round"


@rpc("any_peer","reliable","call_local")
func confirm_player(player_id):
	players_to_confirm.erase(player_id)
	print("PLAYERS TO CONFIRM: " + str(players_to_confirm))
	if players_to_confirm.is_empty():
		initiate_game()


func initiate_game():
	round_won = false
	var blocks = get_random_blocks()
	setup_round.rpc(blocks)
	
	
	for id in players_to_spawn:
		var player_instance = player_scene.instantiate()
		player_instance.name = str(id)
		%PlayerContainer.add_child(player_instance,true)
		player_instance.global_position = Vector2(32,480)

func get_random_blocks():
	var new_blocks = [] 
	for x in range(1,17):
		for y in range(0,9):
			if randf_range(0,1) < 0.2:
				new_blocks.append(Vector2i(x,y))
	return new_blocks

@rpc("authority","reliable","call_local")
func setup_round(new_block_list):
	%GameOverScreen.hide()
	for new_block_position : Vector2i in new_block_list:
		var block_instance = block_scene.instantiate()
		block_instance.global_position.x = origin_position.x + (new_block_position.x * 64)
		block_instance.global_position.y = origin_position.y - (new_block_position.y * 64)
		block_instance.name = str(block_index)
		block_index += 1
		%BlockContainer.add_child(block_instance,true)


func _on_ready_button_pressed():
	player_ready.rpc_id(1,multiplayer.get_unique_id())
	%ReadyCheckBox.set_pressed_no_signal(true)

@rpc("any_peer","reliable","call_local")
func player_ready(player_id):
	players_ready.erase(player_id)
	print(players_ready)
	if players_ready.is_empty():
		clear_level.rpc()
		

@rpc("any_peer","reliable","call_local")
func clear_level():
		for c in %BlockContainer.get_children():
			c.queue_free()
		for c in %PlayerContainer.get_children():
			c.queue_free()
		
		confirm_player.rpc_id(1,multiplayer.get_unique_id())
