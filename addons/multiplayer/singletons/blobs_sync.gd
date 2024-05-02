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
	receive_blob_state.rpc_id(0, state)


func client_sync_state() -> void:
	if blob_buffer.size() <= 1:
		return

	var render_time := Multiplayer.client_clock - INTERPOLATION_OFFSET

	while blob_buffer.size() > 2 and render_time > blob_buffer[1]["time"]:
		blob_buffer.remove_at(0)
	var interpolation_factor = float(render_time - blob_buffer[0]["time"]) / float(blob_buffer[1]["time"] - blob_buffer[0]["time"])

	for blob in Blob.get_blobs():
		var blob_id = blob.get_id()
		if blob_id in blob_buffer[0] and blob_id in blob_buffer[1]:
			blob.set_sync_state(blob_buffer[0][blob_id], blob_buffer[1][blob_id], interpolation_factor)


@rpc("unreliable_ordered")
func receive_blob_state(new_state: Dictionary) -> void:
	blob_buffer.push_back(new_state)
	# TODO re-add me
	#for index in blob_buffer.size():
		#if new_state["time"] > blob_buffer[index]["time"]:
			#blob_buffer.insert(index, new_state)
