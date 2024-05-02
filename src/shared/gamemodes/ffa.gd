extends Node


func _ready() -> void:
	Multiplayer.player_joined.connect(_on_player_joined)
	Multiplayer.player_left.connect(_on_player_left)


func _on_player_joined(_player: Player) -> void:
	if multiplayer.is_server():
		var rand_spawnpoint := Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var blob := Multiplayer.server_spawn_blob(
			"res://src/shared/blobs/character/character.tscn", [-1, rand_spawnpoint, 0]
		)
		blob.server_set_player_id.rpc(_player.get_id())


func _on_player_left(player: Player) -> void:
	if multiplayer.is_server():
		if player.has_blob():
			var blob_id := player.get_blob_id()
			Multiplayer.server_remove_blob_by_id.rpc(blob_id)
