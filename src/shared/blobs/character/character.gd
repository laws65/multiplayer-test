extends Node


var selected_slot_index: int = 0



@rpc("any_peer", "reliable")
func change_weapon_slot(slot_index: int) -> void:
	if get_parent().get_player_id() != multiplayer.get_remote_sender_id():
		return

	set_slot_index.rpc_id(0, slot_index)


func _on_character_player_server_tick(blob: Blob) -> void:
	var axis := Vector2(
		int(Inputs.get_input("right")) - int(Inputs.get_input("left")),
		int(Inputs.get_input("down")) - int(Inputs.get_input("up"))
	).normalized()
	blob.velocity = axis * 200
	blob.look_at(Inputs.get_input("mouse_pos", Vector2.ZERO))
	blob.move_and_slide()


func _on_character_player_client_tick(_blob: Blob) -> void:
	if Input.is_action_just_pressed("primary"):
		request_change_slot_index(0)
	elif Input.is_action_just_pressed("secondary"):
		request_change_slot_index(1)
	elif Input.is_action_just_pressed("tertiary"):
		request_change_slot_index(2)


func request_change_slot_index(index: int) -> void:
	if selected_slot_index == index:
		return
	set_slot_index(index)
	change_weapon_slot.rpc_id(1, index)


@rpc("call_local")
func set_slot_index(index: int) -> void:
	if selected_slot_index == index:
		return
	selected_slot_index = index
	var slots = [$"../Ak", $"../Glock", $"../Knife"]
	for slot in slots:
		slot.hide()
	slots[index].show()
