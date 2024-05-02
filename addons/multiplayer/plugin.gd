@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("Multiplayer", "res://addons/multiplayer/multiplayer.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("Multiplayer")
