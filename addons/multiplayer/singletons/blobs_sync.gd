extends GameScript


var blob_buffer: Array[Dictionary] = []
var max_buffer_size := 5

const INTERPOLATION_OFFSET := 0.1


func _physics_process(_delta: float) -> void:
	if Multiplayer.is_server():
		server_broadcast_state()
	else:
		client_sync_state()


func server_broadcast_state() -> void:
	var state := {}
	var blobs := Blob.get_blobs()
	for blob in blobs:
		state[blob.get_id()] = blob.get_sync_state()
	state["time"] = Time.get_unix_time_from_system()
	for player in Player.get_players():
		var player_id: int = player.get_id()
		var input_number: int = player._server_last_acknowledged_input
		receive_blob_state.rpc_id(player_id, state, input_number)


func client_sync_state() -> void:
	if blob_buffer.size() <= 1:
		return

	var render_time := Clock.time - INTERPOLATION_OFFSET

	while blob_buffer.size() > 2 and render_time > blob_buffer[1]["time"]:
		blob_buffer.remove_at(0)
	var interpolation_factor = float(render_time - blob_buffer[0]["time"]) / float(blob_buffer[1]["time"] - blob_buffer[0]["time"])

	for blob in Blob.get_blobs():
		var blob_id = blob.get_id()
		if blob_id in blob_buffer[0] and blob_id in blob_buffer[1]:
			blob.set_sync_state(blob_buffer[0][blob_id], blob_buffer[1][blob_id], interpolation_factor)


@rpc("unreliable_ordered")
func receive_blob_state(new_state: Dictionary, input_number: int) -> void:
	blob_buffer.push_back(new_state)

	if Multiplayer.has_client_blob():
		var blob := Multiplayer.get_client_blob()
		var unacknowledged_inputs := _client_acknowledge_input(input_number)
		#blob.get_node("Character").ghost.position = new_state[blob.get_id()][0]
		blob.get_node("Character").set_new_pos(new_state[blob.get_id()][0])
		blob.get_node("Character").ghost.rotation = new_state[blob.get_id()][1]
		for number in unacknowledged_inputs:
			blob.get_node("Character")._simulate_physics_frame(blob, Inputs._client_unacknowledged_inputs[number])

	# TODO re-add me
	#for index in blob_buffer.size():
		#if new_state["time"] > blob_buffer[index]["time"]:
			#blob_buffer.insert(index, new_state)


func _client_acknowledge_input(last_acknowledged_input: int) -> Array:
	var input_numbers := Inputs._client_unacknowledged_inputs.keys()
	input_numbers.sort()
	for number in input_numbers:
		if number <= last_acknowledged_input:
			input_numbers.erase(number)
			Inputs._client_unacknowledged_inputs.erase(number)
	return input_numbers
