extends GameScript


var input_buffer: Dictionary
var max_buffer_size := 5

var _player_input_id: int = -1


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		var inputs := collect_inputs()
		receive_client_inputs.rpc_id(1, inputs)


func collect_inputs() -> Dictionary:
	var out := {}
	for input_name in ["left", "right", "up", "down"]:
		out[input_name] = Input.is_action_pressed(input_name)
	out["mouse_pos"] = get_tree().root.get_node("Main/World").get_global_mouse_position()

	out["time"] = Time.get_ticks_msec()
	return out


@rpc("any_peer", "unreliable")
func receive_client_inputs(inputs: Dictionary) -> void:
	var player_id := multiplayer.get_remote_sender_id()

	if not input_buffer.has(player_id):
		input_buffer[player_id] = [inputs]
		return

	for index in input_buffer[player_id].size():
		if inputs["time"] > input_buffer[player_id][index]["time"]:
			input_buffer[player_id].insert(index, inputs)

	while input_buffer[player_id].size() > max_buffer_size:
		input_buffer[player_id].pop_back()


func get_input(input_name: String, return_value_if_null: Variant=0) -> Variant:
	assert(Game.player_id_exists(_player_input_id), "Set target player id with set_player_id(id)")

	if not _player_input_id in input_buffer.keys():
		return return_value_if_null

	if not input_buffer[_player_input_id].front().has(input_name):
		return return_value_if_null

	return input_buffer[_player_input_id].front()[input_name]


func set_player_id(player_id: int) -> void:
	_player_input_id = player_id


func set_player(player: Player) -> void:
	_player_input_id = player.get_id()
