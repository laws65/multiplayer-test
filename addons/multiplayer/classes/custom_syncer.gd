extends Node
class_name CustomBlobSyncer


var parent_blob: Blob

## When you add new properties to be synced every frame, override this
func get_sync_state() -> Array:
	return [parent_blob.position, parent_blob.rotation]


## When you add new properties to be synced every frame, override this
func set_sync_state(info_old: Array, info_new: Array, interpolation_factor: float) -> void:
	parent_blob.position = lerp(info_old[0], info_new[0], interpolation_factor)
	parent_blob.rotation = lerp_angle(info_old[1], info_new[1], interpolation_factor)


## When you add new general properties to be added, override this
func get_spawn_data() -> Array:
	return [parent_blob.scene_file_path, parent_blob.get_id(), parent_blob._player_id, parent_blob.position, parent_blob.rotation]


## When you add new general properties to be added, override this
func set_spawn_data(info: Array) -> void:
	parent_blob.name = str(info[0])
	parent_blob._player_id = info[1]
	parent_blob.position = info[2]
	parent_blob.rotation = info[3]
