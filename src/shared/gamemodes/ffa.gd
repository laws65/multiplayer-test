extends Node


func _ready() -> void:
	Game.player_joined.connect(_on_player_joined)
	Game.player_left.connect(_on_player_left)


func _on_player_joined(_player: Player) -> void:
	if multiplayer.is_server():
		var rand_spawnpoint := Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var blob := Server.spawn_blob(
			"res://src/shared/blobs/character/character.tscn", [-1, rand_spawnpoint, 0, 0]
		)
		blob.server_set_player_id.rpc(_player.get_id())


func _on_player_left(player: Player) -> void:
	if multiplayer.is_server():
		if player.has_blob():
			var blob_id := player.get_blob_id()
			Game.remove_blob_by_id.rpc(blob_id)
