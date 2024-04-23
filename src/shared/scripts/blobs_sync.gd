extends GameScript


var blob_buffer: Array[Dictionary] = []
var max_buffer_size := 5


func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		server_broadcast_state()
	else:
		client_sync_state()


func server_broadcast_state() -> void:
	var state := {}
	var blobs := Game.get_blobs()
	for blob in blobs:
		state[blob.get_id()] = blob.get_sync_state()
	state["time"] = Time.get_ticks_msec()
	receive_blob_state.rpc_id(0, state)


func client_sync_state() -> void:
	if blob_buffer.is_empty():
		return

	for blob in Game.get_blobs():
		var blob_id = blob.get_id()
		if blob_id in blob_buffer.back():
			blob.set_sync_state(blob_buffer.back()[blob_id])


@rpc("unreliable")
func receive_blob_state(new_state: Dictionary) -> void:
	if blob_buffer.is_empty():
		blob_buffer = [new_state]
		return

	blob_buffer.push_back(new_state)
	# TODO re-add me
	#for index in blob_buffer.size():
		#if new_state["time"] > blob_buffer[index]["time"]:
			#blob_buffer.insert(index, new_state)

	while blob_buffer.size() > max_buffer_size:
		blob_buffer.pop_front()
