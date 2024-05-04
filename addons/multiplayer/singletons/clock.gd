extends GameScript


var latency: float
var time: float
var _latency_array = []
var _delta_latency = 0


func _ready() -> void:
	Multiplayer.connection_started.connect(_on_connection_started)


func _physics_process(delta: float) -> void:
	if Multiplayer.is_client():
		time += delta + _delta_latency
		_delta_latency = 0


func _on_connection_started() -> void:
	_fetch_server_time.rpc_id(1, Time.get_unix_time_from_system())
	_determine_latency()


@rpc("any_peer", "reliable")
func _fetch_server_time(client_time: float) -> void:
	var player_id := multiplayer.get_remote_sender_id()
	_return_server_time.rpc_id(player_id, Time.get_unix_time_from_system(), client_time)


@rpc("reliable")
func _return_server_time(server_time: float, client_time: float) -> void:
	latency = (Time.get_unix_time_from_system()-client_time)/2.0
	time = server_time + latency


func _determine_latency() -> void:
	if not Multiplayer.server_active():
		return
	await get_tree().create_timer(0.5).timeout
	_server_determine_latency.rpc_id(1, Time.get_unix_time_from_system())
	_determine_latency()


@rpc("any_peer", "reliable")
func _server_determine_latency(client_time: float) -> void:
	var player_id := multiplayer.get_remote_sender_id()
	_return_latency.rpc_id(player_id, client_time)


@rpc("reliable")
func _return_latency(client_time: float) -> void:
	_latency_array.push_back((Time.get_unix_time_from_system()-client_time)/2.0)
	if _latency_array.size() == 9:
		var total_latency = 0
		_latency_array.sort()
		var mid_point = _latency_array[4]
		for i in range(_latency_array.size()-1, -1, -1):
			if _latency_array[i] > (2.0 * mid_point) and _latency_array[i] > 0.02:
				_latency_array.remove_at(i)
			else:
				total_latency += _latency_array[i]
		var new_latency = total_latency / float(_latency_array.size())
		_delta_latency = new_latency - latency
		latency = new_latency
		_latency_array.clear()
