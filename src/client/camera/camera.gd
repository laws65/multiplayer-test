extends Camera2D


var offset_lerp_strength := 5.0
var position_lerp_strength := 5.0
var deadzone_width_proportion := 0.15

@onready
var deadzone_size := get_viewport_rect().size.x * deadzone_width_proportion


func _ready() -> void:
	get_tree().root.size_changed.connect(
		func(): deadzone_size = get_viewport_rect().size.x * deadzone_width_proportion
	)


func _process(delta: float) -> void:
	if Multiplayer.is_server():
		return

	if Multiplayer.has_client_blob():
		var blob := Multiplayer.get_client_blob()
		position = lerp(position, blob.position, delta*position_lerp_strength)

		var mouse_offset := get_viewport().get_mouse_position() - get_viewport_rect().size*0.5
		var screen_size := get_viewport_rect().size
		mouse_offset.x = clamp(mouse_offset.x, -screen_size.x*0.5, screen_size.x*0.5)
		mouse_offset.y = clamp(mouse_offset.y, -screen_size.y*0.5, screen_size.y*0.5)

		var target_offset := Vector2.ZERO
		deadzone_size = 200
		if mouse_offset.length() > deadzone_size:
			target_offset = mouse_offset.normalized() * (mouse_offset.length() - deadzone_size) * 0.2

		offset = lerp(offset, target_offset, delta*offset_lerp_strength)
