extends Label


func _ready() -> void:
	Game.player_joined.connect(_on_Player_joined)
	Game.player_left.connect(_on_Player_left)


func _on_Player_joined(_player: Player) -> void:
	_update_list()


func _on_Player_left(_player: Player) -> void:
	_update_list()


func _update_list() -> void:
	text = "Players:"
	var player_list := Game.get_players()
	for player in player_list:
		text += "\n" + player.get_username()


