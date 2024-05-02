extends Node
class_name Player


signal blob_id_changed(old_blob_id, new_blob_id)

var _username: String
var _blob_id: int


func _init(id: int, username: String="Invalid Player", blob_id: int=-1) -> void:
	name = str(id)
	_username = username
	_blob_id = blob_id


func get_id() -> int:
	return int(str(name))


func is_valid() -> bool:
	return get_id() > 0 and self in Multiplayer.get_players()


func serialise() -> Array:
	return [get_id(), _username, _blob_id]


static func deserialise(info: Array) -> Player:
	return Player.new(info[0], info[1], info[2])


func has_blob() -> bool:
	return Blob.blob_id_exists(_blob_id)

func get_blob() -> Blob:
	return Blob.get_blob_by_id(_blob_id)


func get_blob_id() -> int:
	return _blob_id


func get_username() -> String:
	return _username


func server_set_blob_id(blob_id: int) -> void:
	assert(Multiplayer.is_server())
	_set_blob_id.rpc_id(0, blob_id)


func server_set_blob(blob: Blob) -> void:
	assert(Multiplayer.is_server())
	assert(is_instance_valid(blob))
	_set_blob_id.rpc_id(0, blob.get_id())


@rpc("call_local", "reliable")
func _set_blob_id(blob_id: int) -> void:
	set_blob_id(blob_id)
	var blob := Blob.get_blob_by_id(blob_id)
	if blob != null:
		blob.set_player_id(get_id())


func set_blob_id(blob_id: int) -> void:
	blob_id_changed.emit(_blob_id, blob_id)
	_blob_id = blob_id