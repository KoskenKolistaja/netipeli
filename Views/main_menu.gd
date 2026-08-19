extends Control

class_name MainMenu

const DEFAULT_PORT: int = 7000
const DEFAULT_IP: String = "127.0.0.1"

# Dictionary holding player information: { peer_id: player_name }
var players: Dictionary = {}

func _ready() -> void:
	# Network signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	if %NameEdit and not PlayerData.player_name.is_empty():
		%NameEdit.text = PlayerData.player_name
	
	if %IPEdit:
		%IPEdit.text = DEFAULT_IP
		
	%StatusLabel.text = "Status: Idle"
	_update_player_list_ui()

# --- Button Listeners ---

func _on_host_button_pressed() -> void:
	_save_player_name()
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT)
	if error != OK:
		%StatusLabel.text = "Status: Failed to host (Error %d)" % error
		return

	multiplayer.multiplayer_peer = peer
	%StatusLabel.text = "Status: Hosting on port %d..." % DEFAULT_PORT
	
	# Register host (ID 1) in both local dictionary and PlayerData singleton
	PlayerData.clear_players()
	PlayerData.add_player(1, PlayerData.player_name)
	players[1] = PlayerData.player_name
	_update_player_list_ui()
	%PlayButton.show()

func _on_join_button_pressed() -> void:
	_save_player_name()
	
	var ip = %IPEdit.text.strip_edges()
	if ip.is_empty():
		ip = DEFAULT_IP

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, DEFAULT_PORT)
	if error != OK:
		%StatusLabel.text = "Status: Failed to initialize connection (Error %d)" % error
		return

	multiplayer.multiplayer_peer = peer
	%StatusLabel.text = "Status: Connecting to %s..." % ip

# --- Data Handling ---

func _save_player_name() -> void:
	var entered_name: String = %NameEdit.text.strip_edges()
	
	if entered_name.is_empty():
		entered_name = "Player_%d" % randi_range(1000, 9999)
		%NameEdit.text = entered_name
	
	PlayerData.player_name = entered_name

# --- Networking Callbacks ---

func _on_peer_connected(_id: int) -> void:
	pass # Peer handling is done via register_player RPC

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		players.erase(id)
		PlayerData.remove_player(id)
		sync_player_list.rpc(players)

func _on_connected_to_server() -> void:
	%StatusLabel.text = "Status: Connected! Syncing player info..."
	register_player.rpc_id(1, PlayerData.player_name)

func _on_connection_failed() -> void:
	%StatusLabel.text = "Status: Connection Failed!"
	multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
	%StatusLabel.text = "Status: Disconnected from Host."
	players.clear()
	PlayerData.clear_players()
	_update_player_list_ui()
	multiplayer.multiplayer_peer = null

# --- RPC Functions ---

@rpc("any_peer", "call_local", "reliable")
func register_player(new_name: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
		
	players[sender_id] = new_name
	PlayerData.add_player(sender_id, new_name)
	
	# Server broadcasts full updated dictionary to all clients
	if multiplayer.is_server():
		sync_player_list.rpc(players)

@rpc("authority", "call_local", "reliable")
func sync_player_list(updated_players: Dictionary) -> void:
	players = updated_players
	# Sync full network dictionary to PlayerData on all clients
	PlayerData.players = updated_players.duplicate()
	_update_player_list_ui()

# --- UI Refresh ---

func _update_player_list_ui() -> void:
	if PlayerData.players.is_empty():
		%PlayerListLabel.text = "Player List:\n(No players connected)"
		return

	var text = "Players (%d):\n" % PlayerData.players.size()
	for id in PlayerData.players:
		var name_entry = PlayerData.players[id]
		if id == multiplayer.get_unique_id():
			name_entry += " (You)"
		if id == 1:
			name_entry += " [Host]"
		text += "• " + name_entry + "\n"
		
	%PlayerListLabel.text = text

func _on_play_button_pressed() -> void:
	start_game()

func start_game() -> void:
	get_parent().start_game()
