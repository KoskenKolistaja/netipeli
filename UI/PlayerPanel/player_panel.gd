extends Panel
class_name PlayerPanel

var player_id = null




func _ready():
	var game = get_tree().get_first_node_in_group("game")
	
	game.skips_changed.connect(on_skips_updated)
	
	PlayerData.colors_updated.connect(on_colors_updated)
	
	MetaData.win_statistics_updated.connect(on_stats_updated)
	%PlayerNameLabel.text = PlayerData.players[player_id]
	
	
	if PlayerData.player_colors.has(player_id):
		%PlayerIcon.self_modulate = PlayerData.player_colors[player_id]



func on_colors_updated(new_colors):
	if PlayerData.player_colors.has(player_id):
		%PlayerIcon.self_modulate = PlayerData.player_colors[player_id]



func on_skips_updated(new_skips : Array):
	if not new_skips.has(player_id):
		show_skip()

func on_stats_updated(new_stats : Dictionary):
	if new_stats.has(player_id):
		%PlayerScoreLabel.text = str(new_stats[player_id])



func hide_skip():
	%SkipLabel.text = ""

func show_skip():
	%SkipLabel.text = "Skip"



func reset():
	hide_skip()
