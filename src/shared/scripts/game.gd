extends Node


signal player_joined(player: Player)
signal player_left(player: Player)

signal server_physics_frame
signal client_physics_frame


var _players: Dictionary


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


@rpc("call_local", "reliable")
func add_player(player_data: Array, is_new:bool=true) -> void:
	var new_player := Player.deserialise(player_data)
	_players[new_player.get_id()] = new_player
	print("Added player with username " + new_player.get_username())
	if is_new:
		player_joined.emit(new_player)


@rpc("reliable")
func add_blob(scene_path: String, blob_data: Array, _is_new:bool=true) -> void:
	var new_blob := load(scene_path).instantiate() as Blob
	new_blob.set_spawn_data(blob_data)
	get_blobs_parent().add_child(new_blob, true)


@rpc("reliable", "call_local")
func remove_blob_by_id(blob_id: int) -> void:
	var blob := get_blob_by_id(blob_id)
	if blob.has_player():
		blob.get_player().set_blob_id(-1)
	blob.queue_free()


@rpc("call_local", "reliable")
func remove_player_by_id(player_id: int) -> void:
	var player := get_player_by_id(player_id)
	print("Deleting player with username " + player.get_username())
	_players.erase(player_id)
	player_left.emit(player)


func get_blobs() -> Array:
	return get_blobs_parent().get_children() as Array


func get_blob_by_id(blob_id: int) -> Blob:
	if blob_id > 0 and get_blobs_parent().has_node(str(blob_id)):
		return get_blobs_parent().get_node(str(blob_id)) as Blob
	return null


func get_blobs_parent() -> Node2D:
	return get_tree().root.get_node("Main/World/Blobs")


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
