extends Node


func _on_character_player_tick(blob: Blob) -> void:
	var axis := Vector2(
		int(Inputs.get_input("right")) - int(Inputs.get_input("left")),
		int(Inputs.get_input("down")) - int(Inputs.get_input("up"))
	).normalized()
	blob.velocity = axis * 200
	blob.look_at(Inputs.get_input("mouse_pos"))
	blob.move_and_slide()
