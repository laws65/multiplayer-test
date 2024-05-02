extends Resource
class_name Player


signal blob_id_changed(old_blob_id, new_blob_id)

var _id: int
var _username: String
var _blob_id: int


func _init(id: int, username: String="Invalid Player", blob_id: int=-1) -> void:
	_id = id
	_username = username
	_blob_id = blob_id


func is_valid() -> bool:
	return _id > 0 and self in Multiplayer.get_players()


func serialise() -> Array:
	return [_id, _username, _blob_id]


static func deserialise(info: Array) -> Player:
	return Player.new(info[0], info[1], info[2])


func has_blob() -> bool:
	return Multiplayer.blob_id_exists(_blob_id)

func get_blob() -> Blob:
	return Multiplayer.get_blob_by_id(_blob_id)


func get_id() -> int:
	return _id


func get_blob_id() -> int:
	return _blob_id


func get_username() -> String:
	return _username


@rpc("call_local", "reliable")
func server_set_blob_id(blob_id: int) -> void:
	set_blob_id(blob_id)
	var blob := Multiplayer.get_blob_by_id(blob_id)
	if blob != null:
		blob.set_player_id(_id)


func set_blob_id(blob_id: int) -> void:
	blob_id_changed.emit(_blob_id, blob_id)
	_blob_id = blob_id

