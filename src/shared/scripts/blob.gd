extends CharacterBody2D
class_name Blob


signal player_id_changed(old_player_id, new_player_id)
signal player_tick(blob)

var _player_id: int


func _ready() -> void:
	add_to_group("blobs")


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		return

	if not has_player():
		return

	Inputs.set_player_id(_player_id)
	player_tick.emit(self)


@rpc("call_local", "reliable")
func server_set_player_id(player_id: int) -> void:
	set_player_id(player_id)
	var player := Game.get_player_by_id(player_id)
	if player != null:
		player.set_blob_id(get_id())


func set_player_id(player_id: int) -> void:
	player_id_changed.emit(_player_id, player_id)
	_player_id = player_id


func has_player() -> bool:
	return Game.player_id_exists(_player_id)


func get_player_id() -> int:
	return _player_id


func get_id() -> int:
	return int(str(name))


func get_player() -> Player:
	return Game.get_player_by_id(_player_id)


func get_sync_state() -> Array:
	return [position, rotation]


func set_sync_state(info: Array) -> void:
	position = info[0]
	rotation = info[1]


func get_spawn_data() -> Array:
	return [scene_file_path, get_id(), _player_id, position, rotation]


func set_spawn_data(info: Array) -> void:
	name = str(info[0])
	_player_id = info[1]
	position = info[2]
	rotation = info[3]
