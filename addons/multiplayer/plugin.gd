@tool
extends EditorPlugin

# TODO come back and find a way to fix this, for now just manually add
#
#var base_file_path := "res://addons/multiplayer/singletons"
#var singletons: Array[String]
#
#
#func _enter_tree() -> void:
	#var singleton_paths := DirAccess.get_files_at(base_file_path)
	#print(singleton_paths)
	#for path in singleton_paths:
		#var singleton_name := path.get_basename().to_pascal_case()
		#add_autoload_singleton(singleton_name, base_file_path + path)
		#singletons.push_back(singleton_name)
		#print(singleton_name + " " + base_file_path + path)
#
#
#func _exit_tree() -> void:
	#for singleton in singletons:
		#remove_autoload_singleton(singleton)
