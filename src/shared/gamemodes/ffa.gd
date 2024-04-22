extends Node


func _ready() -> void:
	Game.player_joined.connect(_on_player_joined)
	Game.player_left.connect(_on_player_left)


func _on_player_joined(player: Player) -> void:
	if multiplayer.is_server():
		var rand_spawnpoint := Vector2(randf_range(-50, 50), randf_range(-50, 50))
		Server.spawn_blob(
			"res://src/shared/blobs/character/character.tscn", [rand_spawnpoint, 0]
		)


func _on_player_left(player: Player) -> void:
	pass
