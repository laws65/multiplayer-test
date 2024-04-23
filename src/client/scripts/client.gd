extends Node


signal joined_server

var network := ENetMultiplayerPeer.new()

var _join_info_for_server: Array


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
	Server.initialise_player.rpc_id(1, _join_info_for_server)


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
