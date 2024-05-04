extends Node


func _ready() -> void:
	Multiplayer.player_joined.connect(_on_player_joined)
	Multiplayer.player_left.connect(_on_player_left)
	Multiplayer.blob_died.connect(_on_blob_died)


func _on_player_joined(_player: Player) -> void:
	if Multiplayer.is_server():
		var rand_spawnpoint := Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var blob := Multiplayer.server_spawn_blob(
			"res://src/blobs/character/character.tscn", [-1, rand_spawnpoint, 0]
		)
		_player.server_set_blob(blob)


func _on_player_left(player: Player) -> void:
	if Multiplayer.is_server():
		if player.has_blob():
			var blob_id := player.get_blob_id()
			Multiplayer.server_remove_blob_by_id(blob_id)


func _on_blob_died(blob: Blob) -> void:
	if not Multiplayer.is_server():
		return

	if blob.has_player():
		var player := blob.get_player()
		var rand_spawnpoint := Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var new_blob := Multiplayer.server_spawn_blob(
			"res://src/blobs/character/character.tscn", [-1, rand_spawnpoint, 0]
		)
		player.server_set_blob(new_blob)
