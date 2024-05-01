extends Node


signal server_started

var uninitialised_players: Dictionary

var next_blob_id := 1

var network := ENetMultiplayerPeer.new()


func start_server(port: int=50301) -> void:
	var err: = network.create_server(port)
	if err != OK:
		print("Failed to create server with error code " + str(err))
	else:
		print("Listening on port " + str(port))
		multiplayer.set_multiplayer_peer(network)
		multiplayer.peer_connected.connect(_on_Peer_connected)
		multiplayer.peer_disconnected.connect(_on_Peer_disconnected)
		server_started.emit()


@rpc("any_peer", "reliable")
func initialise_player(info: Array) -> void:
	assert(multiplayer.is_server())
	var player_id := multiplayer.get_remote_sender_id()
	if player_id in uninitialised_players.keys():
		uninitialised_players[player_id] = info
		Client.receive_game_info.rpc_id(player_id, Game.get_game_info())


@rpc("any_peer", "reliable")
func client_loading_finished() -> void:
	assert(multiplayer.is_server())
	var player_id := multiplayer.get_remote_sender_id()
	var username := uninitialised_players[player_id][0] as String
	var player_template = Player.new(player_id, username)
	var player_data := player_template.serialise()
	uninitialised_players.erase(player_id)
	Game.add_player.rpc(player_data)


func spawn_blob(scene_path: String, data: Array=[]) -> Blob:
	var new_blob := load(scene_path).instantiate() as Blob
	var new_blob_id := new_blob.get_instance_id()
	data.push_front(new_blob_id)
	new_blob.set_spawn_data(data)
	Game.get_blobs_parent().add_child(new_blob, true)
	Game.add_blob.rpc_id(0, scene_path, data)
	return new_blob


@rpc("any_peer", "reliable")
func fetch_server_time(client_time: float) -> void:
	var player_id := multiplayer.get_remote_sender_id()
	Client.return_server_time.rpc_id(player_id, Time.get_unix_time_from_system(), client_time)


@rpc("any_peer", "reliable")
func determine_latency(client_time: float) -> void:
	var player_id := multiplayer.get_remote_sender_id()
	Client.return_latency.rpc_id(player_id, client_time)


func _on_Peer_connected(id: int) -> void:
	print("Peer connected with id " + str(id))
	uninitialised_players[id] = []


func _on_Peer_disconnected(id: int) -> void:
	print("Peer disconnected with id " + str(id))
	if id in uninitialised_players.keys():
		uninitialised_players.erase(id)
	else:
		Game.remove_player_by_id.rpc(id)
