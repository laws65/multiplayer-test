extends Node


signal joined_server

var network := ENetMultiplayerPeer.new()

var _join_info_for_server: Array


var latency: float
var client_clock: float
var _latency_array = []
var _delta_latency = 0


func _physics_process(delta: float) -> void:
	client_clock += delta + _delta_latency
	_delta_latency = 0



func join_server(ip: String, port: int, join_info_for_server: Array) -> void:
	_join_info_for_server = join_info_for_server
	var err = network.create_client(ip, port)
	if err != OK:
		print("Couldn't join server, error code " + str(err))
	else:
		print("Successfully joined server with ip " + str(ip))
		multiplayer.set_multiplayer_peer(network)
		multiplayer.connected_to_server.connect(_on_Connected_to_server)
		multiplayer.connection_failed.connect(_on_Connection_failed)


func _on_Connected_to_server() -> void:
	print("Successfully joined")
	print(Time.get_unix_time_from_system())
	Server.fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())
	Server.initialise_player.rpc_id(1, _join_info_for_server)
	_determine_latency()


@rpc("reliable")
func return_server_time(server_time: float, client_time: float) -> void:
	latency = (Time.get_unix_time_from_system()-client_time)/2.0
	client_clock = server_time + latency


func _determine_latency() -> void:
	await get_tree().create_timer(0.5).timeout
	Server.determine_latency.rpc_id(1, Time.get_unix_time_from_system())
	_determine_latency()


@rpc("reliable")
func return_latency(client_time: float) -> void:
	_latency_array.push_back((Time.get_unix_time_from_system()-client_time)/2.0)
	if _latency_array.size() == 9:
		var total_latency = 0
		_latency_array.sort()
		var mid_point = _latency_array[4]
		for i in range(_latency_array.size()-1, -1, -1):
			if _latency_array[i] > (2.0 * mid_point) and _latency_array[i] > 0.02:
				_latency_array.remove(i)
			else:
				total_latency += _latency_array[i]
		var new_latency = total_latency / float(_latency_array.size())
		_delta_latency = new_latency - latency
		latency = new_latency
		print("new latency " + str(new_latency))
		_latency_array.clear()


func _on_Connection_failed() -> void:
	print("Couldn't join server")


@rpc("reliable")
func receive_game_info(info: Array, finished: bool=true) -> void:
	var player_data_list := info[0] as Array
	var blob_data_list := info[1] as Array

	for player_data in player_data_list:
		Game.add_player(player_data, false)

	for blob_data in blob_data_list:
		var scene_path: String = blob_data.pop_front()
		Game.add_blob(scene_path, blob_data, false)

	if finished:
		Server.client_loading_finished.rpc_id(1)
		joined_server.emit()


func get_player() -> Player:
	return Game.get_player_by_id(get_player_id())


func get_player_id() -> int:
	return multiplayer.get_unique_id()
