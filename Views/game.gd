extends Node2D

#17,9

signal skips_changed(skips)

var block_index = 0

@export var block_scene : PackedScene
@export var player_scene : PackedScene

@export var player_panel_scene : PackedScene

var block_list : Array = []

var origin_position = Vector2(32,608) 

var players_to_confirm = []

var players_to_spawn = []

var players_ready = []

var round_over = false

var skips = []

var alive_players = []

func _ready():
	%WinArea.player_finished.connect(on_player_finished)
	
	for key in PlayerData.players.keys():
		MetaData.win_statistics[key] = 0
		MetaData.player_coins[key] = 0
		spawn_player_panel(key)
	
	
	
	if not multiplayer.is_server():
		await get_tree().create_timer(0.1).timeout
		confirm_player.rpc_id(1,multiplayer.get_unique_id())
	else:
		%AudioStreamPlayer.play()
		print("PLAYERS TO CONFIRM: " + str(players_to_confirm))
		for key in PlayerData.players.keys():
			players_to_spawn.append(key)
			if key == 1:
				continue
			else:
				players_to_confirm.append(key)
	
	#set_scores()


func _process(delta):
	if Input.is_action_just_pressed("skip"):
		skip.rpc_id(1,multiplayer.get_unique_id())

func _physics_process(delta):
	%TimeLabel.text = str(snappedi(%Timer.time_left,1))


func spawn_player_panel(player_id):
	var panel_instance : PlayerPanel = player_panel_scene.instantiate()
	panel_instance.player_id = player_id
	%PlayerPanelContainer.add_child(panel_instance)


@rpc("any_peer","reliable","call_local")
func skip(player_id):
	if skips.has(player_id):
		skips.erase(player_id)
	if skips.is_empty():
		skip_round()
	sync_skips.rpc(skips)

@rpc("authority","reliable","call_local")
func sync_skips(new_skips):
	skips = new_skips
	skips_changed.emit(skips)


func on_player_finished(player_id):
	if round_over:
		return
	
	round_over = true
	MetaData.request_change_coin.rpc_id(1,1,player_id)
	
	MetaData.player_won(player_id)
	
	
	print("PLAYER " + str(player_id) + " WON!" )
	game_over.rpc(player_id)
	for p_id in PlayerData.players.keys():
		players_ready.append(p_id)
	
	for p_id in PlayerData.players.keys():
		players_to_confirm.append(p_id)
	
	var winning_text : String = "+1 🪙 for finishing 1st \n"
	add_winning_text.rpc_id(player_id,winning_text)

@rpc("authority","reliable","call_local")
func add_winning_text(exp_text : String):
	%CoinLabel.text += exp_text



func skip_round():
	if round_over:
		return
	round_over = true
	
	for p_id in PlayerData.players.keys():
		players_ready.append(p_id)
	for p_id in PlayerData.players.keys():
		players_to_confirm.append(p_id)
	
	game_over.rpc(null)

@rpc("authority","reliable","call_local")
func game_over(player_id):
	if multiplayer.is_server():
		delete_items()
		
		for p in alive_players:
			MetaData.player_change_coin(1,p)
			add_winning_text.rpc_id(p,"+1 🪙 for surviving the round \n")
	%TimeLabel.text = str(snappedi(0,1))
	%Timer.stop()
	%GameOverScreen.show()
	%ReadyButton.grab_focus()
	%ReadyCheckBox.set_pressed_no_signal(false)
	%WinnerTextLabel.text = "No Winner"
	if player_id:
		%WinnerTextLabel.text = PlayerData.players[player_id] + " won the round"
	
	#set_scores()




func delete_items():
	for i in get_tree().get_nodes_in_group("item"):
		i.queue_free()


func set_scores():
	var scores = MetaData.win_statistics
	var lines: Array[String] = []

	# Sort by wins, highest first
	var sorted_scores = scores.keys()
	sorted_scores.sort_custom(func(a, b):
		return scores[a] > scores[b]
	)

	for player_id in sorted_scores:
		var player_name = PlayerData.players[player_id]
		var wins = scores[player_id]
		lines.append("%s — %d %s" % [
			player_name,
			wins,
			"win" if wins == 1 else "wins"
		])

	%ScoreLabel.text = "\n".join(lines)



@rpc("any_peer","reliable","call_local")
func confirm_player(player_id):
	players_to_confirm.erase(player_id)
	print("PLAYERS TO CONFIRM: " + str(players_to_confirm))
	if players_to_confirm.is_empty():
		initiate_game()

func player_died(player_id):
	alive_players.erase(player_id)
	skip(player_id)

func initiate_game():

	round_over = false
	var blocks = get_random_blocks()
	setup_round.rpc(blocks)
	
	skips.clear()
	skips = PlayerData.players.keys()
	alive_players.clear()
	alive_players = PlayerData.players.keys()
	
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
	%CoinLabel.text = ""
	
	for c in %PlayerPanelContainer.get_children():
		if c is PlayerPanel:
			c.reset()
	
	
	for new_block_position : Vector2i in new_block_list:
		var block_instance = block_scene.instantiate()
		block_instance.global_position.x = origin_position.x + (new_block_position.x * 64)
		block_instance.global_position.y = origin_position.y - (new_block_position.y * 64)
		block_instance.name = str(block_index)
		block_index += 1
		%BlockContainer.add_child(block_instance,true)
	%Timer.start()

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


func _on_timer_timeout():
	if multiplayer.is_server():
		skip_round()
