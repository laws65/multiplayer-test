extends Node
class_name GameScript


func _ready() -> void:
	set_physics_process(false)
	Server.server_started.connect(set_physics_process.bind(true))
	Client.joined_server.connect(set_physics_process.bind(true))
