extends CharacterBody2D
class_name Blob


signal player_id_changed(old_player_id: int, new_player_id: int)
signal player_server_tick(blob: Blob)
signal player_client_tick(blob: Blob)

var _player_id: int

@export
var _syncer: CustomBlobSyncer ## Custom syncer for general and every tick data, can leave empty


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		add_to_group("blobs")
		_setup_syncer()


func _physics_process(_delta: float) -> void:
	if not has_player():
		return
	if Multiplayer.is_server():
		Inputs.set_player_id(_player_id)
		player_server_tick.emit(self)
	elif get_player_id() == multiplayer.get_unique_id():
		player_client_tick.emit(self)


func server_set_player_id(player_id: int) -> void:
	assert(Multiplayer.is_server(), "Must be called on server")
	_set_player_id.rpc_id(0, player_id)


func server_set_player(player: Player) -> void:
	assert(Multiplayer.is_server(), "Must be called on server")
	_set_player_id.rpc_id(0, player.get_id())


@rpc("call_local", "reliable")
func _set_player_id(player_id: int) -> void:
	set_player_id(player_id)
	var player := Player.get_player_by_id(player_id)
	if player != null:
		player.set_blob_id(get_id())


func set_player_id(player_id: int) -> void:
	player_id_changed.emit(_player_id, player_id)
	_player_id = player_id


func has_player() -> bool:
	return Player.player_id_exists(_player_id)


func get_player_id() -> int:
	return _player_id


func get_id() -> int:
	return int(str(name))


func get_player() -> Player:
	return Player.get_player_by_id(_player_id)


func get_sync_state() -> Array:
	return _syncer.get_sync_state()


func set_sync_state(info_old: Array, info_new: Array, interpolation_factor: float) -> void:
	_syncer.set_sync_state(info_old, info_new, interpolation_factor)


func get_spawn_data() -> Array:
	return _syncer.get_spawn_data()


func set_spawn_data(info: Array) -> void:
	_syncer.set_spawn_data(info)


func _setup_syncer() -> void:
	if not is_instance_valid(_syncer):
		_syncer = CustomBlobSyncer.new()
		add_child(_syncer)
	_syncer.parent_blob = self


static func get_blobs() -> Array:
	return Multiplayer.get_blobs_parent().get_children()


static func blob_id_exists(blob_id: int) -> bool:
	return blob_id > 0 and Multiplayer.get_blobs_parent().has_node(str(blob_id))


static func get_blob_by_id(blob_id: int) -> Blob:
	if blob_id > 0 and Multiplayer.get_blobs_parent().has_node(str(blob_id)):
		return Multiplayer.get_blobs_parent().get_node(str(blob_id)) as Blob
	return null
