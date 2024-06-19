extends CharacterBody2D


var target_position: Vector2:
	set(value):
		lerp_factor = 0.0
		old_position = target_position
		target_position = value

var old_position: Vector2
var lerp_factor: float


func _ready() -> void:
	Reconciliator.rollback.connect(_rollback)
	Reconciliator.simulate_frame.connect(_simulate_physics_frame)


func _process(delta: float) -> void:
	lerp_factor += delta / get_physics_process_delta_time()
	position = lerp(old_position, target_position, lerp_factor)
	look_at(get_global_mouse_position())


func _rollback(state: Dictionary) -> void:
	if not Multiplayer.has_client_blob():
		return
	var blob := Multiplayer.get_client_blob()
	if blob.get_id() in state:
		rotation = state[blob.get_id()][1]
		target_position = state[blob.get_id()][0]


func _simulate_physics_frame(inputs: Dictionary) -> void:
	var axis := Vector2(
		int(inputs["right"]) - int(inputs["left"]),
		int(inputs["down"]) - int(inputs["up"])
	).normalized()
	look_at(Vector2(inputs["mouse_pos"]))
	target_position += axis * 200 * get_physics_process_delta_time()
