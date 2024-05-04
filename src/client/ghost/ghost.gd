extends CharacterBody2D


func _physics_process(_delta: float) -> void:
	var axis := Input.get_vector("left", "right", "up", "down")
	velocity = axis * 200
	look_at(get_global_mouse_position())
	move_and_slide()
