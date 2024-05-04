extends Node


var selected_slot_index: int = SLOT_PRIMARY

var inventory := [-1, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0]


var most_recent_slot_change_request_time := 0.0

enum {
	SLOT_PRIMARY=0,
	SLOT_SECONDARY=1,
	SLOT_KNIFE=2,
	SLOT_ZEUS=0,
	SLOT_BOMB=3,
	SLOT_SMOKE=4,
	SLOT_FLASH=5,
	SLOT_HE=6,
	SLOT_MOLOTOV=7,
	SLOT_DECOY=8,
	SLOT_STIM=9,
}


@rpc("any_peer", "reliable")
func change_weapon_slot(slot_index: int) -> void:
	if get_parent().get_player_id() != multiplayer.get_remote_sender_id():
		return
	set_slot_index.rpc_id(0, slot_index, Time.get_unix_time_from_system())


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
		request_change_slot_index(SLOT_PRIMARY)
	elif Input.is_action_just_pressed("secondary"):
		request_change_slot_index(SLOT_SECONDARY)
	elif Input.is_action_just_pressed("tertiary"):
		request_change_slot_index(SLOT_KNIFE)


func request_change_slot_index(index: int) -> void:
	if selected_slot_index == index:
		return
	client_set_slot_index(index)
	change_weapon_slot.rpc_id(1, index)
	most_recent_slot_change_request_time = Clock.time


func client_set_slot_index(index):
	selected_slot_index = index
	var slots = [$"../Ak", $"../Glock", $"../Knife"]
	for slot in slots:
		slot.hide()
	slots[index].show()


@rpc("call_local", "reliable")
func set_slot_index(index: int, server_time: float=0) -> void:
	if selected_slot_index == index:
		return
	if (Multiplayer.is_client()
	and get_parent().is_my_blob()
	and server_time + Clock.latency > most_recent_slot_change_request_time):
		return
	client_set_slot_index(index)


func _on_character_player_id_changed(_old_player_id: int, _new_player_id: int) -> void:
	if get_parent().is_my_blob():
		var instance = load("res://src/client/ghost/ghost.tscn").instantiate()
		get_parent().get_parent().get_parent().add_child(instance)
		instance.position = get_parent().position
