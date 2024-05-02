extends Control


func _on_host_game_button_up() -> void:
	Multiplayer.start_server(int(get_node("%ServerPort").text))
	hide()
	get_node("../Control/Server").show()


func _on_join_game_button_up() -> void:
	var username: String = get_node("%Username").text
	var ip: String = get_node("%JoinIP").text
	var port:= int(get_node("%JoinPort").text)

	Multiplayer.join_server(ip, port, [username])
	hide()
	get_node("../Control/Client").show()
