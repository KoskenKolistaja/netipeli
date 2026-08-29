extends Node


signal coins_updated(amount)
signal win_statistics_updated(stats)

var win_statistics = {}

var player_coins = {}






func player_won(player_id):
	win_statistics[player_id] = win_statistics[player_id] + 1
	sync_win_statistics.rpc(win_statistics)
	win_statistics_updated.emit(win_statistics)

func has_amount_of_coins(amount,player_id) -> bool:
	if not player_coins.has(player_id):
		return false
	elif player_coins[player_id] >= amount:
		return true
	else:
		return false


@rpc("authority","reliable")
func sync_win_statistics(new_stats):
	win_statistics = new_stats
	win_statistics_updated.emit(win_statistics)

func pre_change_coin(amount,player_id):
	
	if player_id == 1:
		return
	
	if player_coins.has(player_id):
		player_coins[player_id] += amount
		coins_updated.emit(player_coins[player_id])


@rpc("any_peer","reliable","call_local")
func request_change_coin(amount,player_id):
	player_change_coin(amount,player_id)


func player_change_coin(amount,player_id):
	player_coins[player_id] += amount
	update_player_coins.rpc_id(player_id,player_coins)

@rpc("authority","reliable","call_local")
func update_player_coins(new_player_coins):
	player_coins = new_player_coins
	
	var id = multiplayer.get_unique_id()
	
	if player_coins.has(id):
		coins_updated.emit(player_coins[id])
