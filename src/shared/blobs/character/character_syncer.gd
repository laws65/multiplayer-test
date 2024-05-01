extends CustomBlobSyncer


func get_spawn_data() -> Array:
	var out := super()
	out.push_back($"../Character".selected_slot_index)
	return out


func set_spawn_data(data: Array) -> void:
	super(data)
	$"../Character".set_slot_index(data[4])
