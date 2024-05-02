extends Node


signal player_joined(player: Player)
signal player_left(player: Player)
signal server_started

signal joined_server

# Server vars
var uninitialised_peers := {}

var _players: Dictionary


# Client vars
var _join_info_for_server: Array
var latency: float
var client_clock: float
var _latency_array = []
var _delta_latency = 0
var input_collector := Input


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		client_clock += delta + _delta_latency
		_delta_latency = 0


@rpc("any_peer", "reliable")
func _client_loading_finished() -> void:
	assert(multiplayer.is_server())
	var player_id := multiplayer.get_remote_sender_id()
	var username := uninitialised_peers[player_id][0] as String
	var player_template = Player.new(player_id, username)
	var player_data := player_template.serialise()
	uninitialised_peers.erase(player_id)
	_add_player.rpc(player_data)


func client_set_input_function(input_function: Callable) -> void:
	pass


func start_server(port: int=50301) -> void:
	var network := ENetMultiplayerPeer.new()
	var err: = network.create_server(port)
	if err != OK:
		print("Failed to create server with error code " + str(err))
	else:
		print("Listening on port " + str(port))
		multiplayer.set_multiplayer_peer(network)
		multiplayer.peer_connected.connect(_on_Peer_connected)
		multiplayer.peer_disconnected.connect(_on_Peer_disconnected)
		server_started.emit()


func _on_Connected_to_server() -> void:
	print("Successfully joined")
	_fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())
	_initialise_player.rpc_id(1, _join_info_for_server)
	_determine_latency()


func _determine_latency() -> void:
	await get_tree().create_timer(0.5).timeout
	_server_determine_latency.rpc_id(1, Time.get_unix_time_from_system())
	_determine_latency()


func _on_Connection_failed() -> void:
	pass


func _on_Peer_connected(id: int) -> void:
	print("Peer connected with id " + str(id))
	uninitialised_peers[id] = {}


func _on_Peer_disconnected(id: int) -> void:
	print("Peer disconnected with id " + str(id))
	if id in uninitialised_peers.keys():
		uninitialised_peers.erase(id)
	else:
		_server_remove_player_by_id.rpc_id(0, id)


@rpc("call_local", "reliable")
func _server_remove_player_by_id(player_id: int) -> void:
	var player := get_player_by_id(player_id)
	print("Deleting player with username " + player.get_username())
	_players.erase(player_id)
	player_left.emit(player)


@rpc("call_local", "reliable")
func _add_player(player_data: Array, is_new:bool=true) -> void:
	var new_player := Player.deserialise(player_data)
	_players[new_player.get_id()] = new_player
	print("Added player with username " + new_player.get_username())
	if is_new:
		player_joined.emit(new_player)


func server_spawn_blob(scene_path: String, data: Array=[]) -> Blob:
	var new_blob := load(scene_path).instantiate() as Blob
	var new_blob_id := new_blob.get_instance_id()
	data.push_front(new_blob_id)
	new_blob.set_spawn_data(data)
	get_blobs_parent().add_child(new_blob, true)
	_add_blob.rpc_id(0, scene_path, data)
	return new_blob


@rpc("reliable")
func _add_blob(scene_path: String, blob_data: Array, _is_new:bool=true) -> void:
	var new_blob := load(scene_path).instantiate() as Blob
	new_blob.set_spawn_data(blob_data)
	get_blobs_parent().add_child(new_blob, true)


@rpc("reliable", "call_local")
func server_remove_blob_by_id(blob_id: int) -> void:
	var blob := get_blob_by_id(blob_id)
	if blob.has_player():
		blob.get_player().set_blob_id(-1)
	blob.queue_free()


func get_game_info() -> Array:
	var players_data := []
	var players := get_players()
	for player in players:
		players_data.append(player.serialise())

	var blobs_data := []
	var blobs := get_blobs()
	for blob in blobs:
		blobs_data.append(blob.get_spawn_data())

	return [players_data, blobs_data]

# TODO: Figure out how to make this array Array[int]
func get_player_ids() -> Array:
	return _players.keys()


func player_id_exists(player_id: int) -> bool:
	return player_id > 0 and player_id in get_player_ids()


func blob_id_exists(blob_id: int) -> bool:
	return blob_id > 0 and get_blobs_parent().has_node(str(blob_id))


# TODO: Figure out how to make this array Array[Player]
func get_players() -> Array:
	return _players.values()


func get_player_by_id(player_id: int) -> Player:
	if player_id_exists(player_id):
		return _players[player_id]
	return Player.new(-1)


func get_blobs() -> Array:
	return get_blobs_parent().get_children() as Array


func get_blob_by_id(blob_id: int) -> Blob:
	if blob_id > 0 and get_blobs_parent().has_node(str(blob_id)):
		return get_blobs_parent().get_node(str(blob_id)) as Blob
	return null


func get_blobs_parent() -> Node2D:
	return get_tree().root.get_node("Main/World/Blobs")



func get_client_player() -> Player:
	return get_player_by_id(get_client_id())


func get_client_id() -> int:
	return multiplayer.get_unique_id()


func join_server(ip: String, port: int, join_info_for_server: Array) -> void:
	_join_info_for_server = join_info_for_server
	var network := ENetMultiplayerPeer.new()
	var err = network.create_client(ip, port)
	if err != OK:
		print("Couldn't join server, error code " + str(err))
	else:
		print("Successfully joined server with ip " + str(ip))
		multiplayer.set_multiplayer_peer(network)
		multiplayer.connected_to_server.connect(_on_Connected_to_server)
		multiplayer.connection_failed.connect(_on_Connection_failed)

@rpc("any_peer", "reliable")
func _initialise_player(info: Array) -> void:
	assert(multiplayer.is_server())
	var player_id := multiplayer.get_remote_sender_id()
	if player_id in uninitialised_peers.keys():
		uninitialised_peers[player_id] = info
		_receive_game_info.rpc_id(player_id, get_game_info())

@rpc("reliable")
func _receive_game_info(info: Array, finished: bool=true) -> void:
	var player_data_list := info[0] as Array
	var blob_data_list := info[1] as Array

	for player_data in player_data_list:
		_add_player(player_data, false)

	for blob_data in blob_data_list:
		var scene_path: String = blob_data.pop_front()
		_add_blob(scene_path, blob_data, false)

	if finished:
		_client_loading_finished.rpc_id(1)
		joined_server.emit()


@rpc("any_peer", "reliable")
func _fetch_server_time(client_time: float) -> void:
	var player_id := multiplayer.get_remote_sender_id()
	_return_server_time.rpc_id(player_id, Time.get_unix_time_from_system(), client_time)


@rpc("reliable")
func _return_server_time(server_time: float, client_time: float) -> void:
	latency = (Time.get_unix_time_from_system()-client_time)/2.0
	client_clock = server_time + latency



@rpc("any_peer", "reliable")
func _server_determine_latency(client_time: float) -> void:
	var player_id := multiplayer.get_remote_sender_id()
	_return_latency.rpc_id(player_id, client_time)


@rpc("reliable")
func _return_latency(client_time: float) -> void:
	_latency_array.push_back((Time.get_unix_time_from_system()-client_time)/2.0)
	if _latency_array.size() == 9:
		var total_latency = 0
		_latency_array.sort()
		var mid_point = _latency_array[4]
		for i in range(_latency_array.size()-1, -1, -1):
			if _latency_array[i] > (2.0 * mid_point) and _latency_array[i] > 0.02:
				_latency_array.remove_at(i)
			else:
				total_latency += _latency_array[i]
		var new_latency = total_latency / float(_latency_array.size())
		_delta_latency = new_latency - latency
		latency = new_latency
		_latency_array.clear()
