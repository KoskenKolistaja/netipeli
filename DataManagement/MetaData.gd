extends Node





var win_statistics = {}

var player_coins = {}






func player_won(player_id):
	win_statistics[player_id] = win_statistics[player_id] + 1
	sync_win_statistics.rpc(win_statistics)


@rpc("authority","reliable")
func sync_win_statistics(new_stats):
	win_statistics = new_stats
