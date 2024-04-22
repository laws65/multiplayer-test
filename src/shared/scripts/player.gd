extends Resource
class_name Player


var _id: int
var _username: String
var _blob_id: int


func _init(id: int, username: String="Invalid Player", blob_id: int=-1) -> void:
	_id = id
	_username = username
	_blob_id = blob_id


func is_valid() -> bool:
	return _id > 0 and self in Game.get_players()


func serialise() -> Array:
	return [_id, _username, _blob_id]


static func deserialise(info: Array) -> Player:
	return Player.new(info[0], info[1], info[2])


func get_blob() -> Blob:
	return Game.get_blob_by_id(_blob_id)


func get_id() -> int:
	return _id


func get_blob_id() -> int:
	return _blob_id


func get_username() -> String:
	return _username
