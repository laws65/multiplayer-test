extends CharacterBody2D
class_name Blob


var _player_id: int


func _ready() -> void:
	add_to_group("blobs")


func has_player() -> bool:
	return Game.player_id_exists(_player_id)


func get_player_id() -> int:
	return _player_id


func get_id() -> int:
	return int(str(name))


func get_player() -> Player:
	return Game.get_player_by_id(_player_id)


func get_sync_data() -> Array:
	return [position, rotation]


func set_sync_data(info: Array) -> void:
	position = info[0]
	rotation = info[1]


func get_spawn_data() -> Array:
	return [scene_file_path, get_id(), position, rotation]


func set_spawn_data(info: Array) -> void:
	name = str(info[0])
	position = info[1]
	rotation = info[2]
