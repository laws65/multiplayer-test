extends Node


signal player_joined(player: Player)
signal player_left(player: Player)
signal server_started

signal joined_server

signal pre_change_map
signal post_change_map
signal pre_change_gamemode
signal post_change_gamemode

# Server vars
var uninitialised_peers := {}

# Client vars
var _join_info_for_server: Array
var latency: float
var client_clock: float
var _latency_array = []
var _delta_latency = 0
var input_collector := Input

var _gamemode_cfg_path := "res://src/gamemodes/ffa/ffa.cfg"
var _map_filepath := "res://src/maps/dust2/dust2.tscn"

var _gamemode_cfg := ConfigFile.new()


func _physics_process(delta: float) -> void:
	if not Multiplayer.is_server():
		client_clock += delta + _delta_latency
		_delta_latency = 0


@rpc("any_peer", "reliable")
func _client_loading_finished() -> void:
	assert(Multiplayer.is_server())
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
		_load_gamemode(_gamemode_cfg_path)


func _on_Connected_to_server() -> void:
	print("Successfully joined")
	_fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())
	_initialise_player.rpc_id(1, _join_info_for_server)
	_determine_latency()


func _determine_latency() -> void:
	if not server_active():
		return
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
	player.queue_free()
	_get_players_parent().remove_child(player)
	print("Deleting player with username " + player.get_username())

	player_left.emit(player)


@rpc("call_local", "reliable")
func _add_player(player_data: Array, is_new:bool=true) -> void:
	var new_player := Player.deserialise(player_data)
	_get_players_parent().add_child(new_player, true)
	print("Added player with username " + new_player.get_username())
	if is_new:
		player_joined.emit(new_player)


func server_spawn_blob(scene_path: String, data: Array=[]) -> Blob:
	assert(is_server(), "Can only spawn blobs on server")
	var new_blob_packed_scene := load(scene_path) as PackedScene
	assert(new_blob_packed_scene.can_instantiate(), "Unable to instantiate packed scene with filepath " + scene_path)
	var new_blob := new_blob_packed_scene.instantiate() as Blob
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


func server_remove_blob_by_id(blob_id: int) -> void:
	assert(is_server())
	_remove_blob_by_id.rpc_id(0, blob_id)

@rpc("reliable", "call_local")
func _remove_blob_by_id(blob_id: int) -> void:
	var blob := Blob.get_blob_by_id(blob_id)
	if blob.has_player():
		blob.get_player().set_blob_id(-1)
	blob.queue_free()


func get_game_info() -> Array:
	var players_data := []
	var players := get_players()
	for player in players:
		players_data.append(player.serialise())

	var blobs_data := []
	var blobs := Blob.get_blobs()
	for blob in blobs:
		blobs_data.append(blob.get_spawn_data())

	var map_file := get_tree().root.get_node("Main/World").scene_file_path

	return [players_data, blobs_data, _map_filepath, _gamemode_cfg_path]


func get_player_ids() -> Array[int]:
	var players := get_players()
	var out: Array[int]
	for player in players:
		out.push_back(player.get_id())
	return out


func player_id_exists(player_id: int) -> bool:
	return player_id > 0 and player_id in get_player_ids()




# TODO: Figure out how to make this array Array[Player]
func get_players() -> Array:
	return _get_players_parent().get_children()


func get_player_by_id(player_id: int) -> Player:
	if player_id_exists(player_id):
		return _get_players_parent().get_node(str(player_id))
	return Player.new(-1)


func get_blobs_parent() -> Node2D:
	return get_tree().root.get_node("Main/World/Blobs")


func get_client_player() -> Player:
	return get_player_by_id(get_client_id())


func get_client_id() -> int:
	if not server_active():
		return -1
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
	assert(Multiplayer.is_server())
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

	var map_filepath := info[2] as String
	var gamemode_cfg_path := info[3] as String
	_load_map(map_filepath)
	_load_gamemode(gamemode_cfg_path)

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


func server_active() -> bool:
	return (multiplayer.has_multiplayer_peer() and
		multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	)

func is_client() -> bool:
	return server_active() and not multiplayer.is_server()


func is_server() -> bool:
	return server_active() and multiplayer.is_server()


func _load_map(file_path: String) -> void:
	print("loading map " + file_path)
	pre_change_map.emit()
	var _map_parent := _get_map_parent()
	var old_filepath := _map_filepath
	for child in _map_parent.get_children():
		_map_parent.remove_child(child)
		child.queue_free()

	_map_filepath = file_path
	var instance = load(_map_filepath).instantiate() as Node2D
	_map_parent.add_child(instance)
	post_change_map.emit()


func _load_gamemode(config_path: String) -> void:
	print("loading gamemode " + config_path)
	pre_change_gamemode.emit()
	var _scripts_parent := _get_scripts_parent()
	for child in _scripts_parent.get_children():
		child.queue_free()
	_gamemode_cfg.load(config_path)
	var scripts_file_list := _gamemode_cfg.get_value("Rules", "scripts") as Array
	for script_filepath in scripts_file_list:
		var node := Node.new()
		node.set_script(load(script_filepath))
		_scripts_parent.add_child(node)
	post_change_gamemode.emit()

	if is_server():
		var map_list := _gamemode_cfg.get_value("Rules", "map_pool")
		_load_map(map_list[map_list.size()-1])


func _get_map_parent() -> Node2D:
	return get_tree().root.get_node("Main/World/MapParent")

func _get_scripts_parent() -> Node:
	return get_tree().root.get_node("Main/Scripts")


func _get_players_parent() -> Node:
	return get_tree().root.get_node("Main/Players")
