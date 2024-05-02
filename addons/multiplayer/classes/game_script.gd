extends Node
class_name GameScript


func _ready() -> void:
	if not Multiplayer.server_active():
		set_physics_process(false)
	Multiplayer.server_started.connect(set_physics_process.bind(true))
	Multiplayer.joined_server.connect(set_physics_process.bind(true))
