extends "res://ui/Lobby.gd"

# offsets the error label depending on if it's in multiplayer or direct play
func _process(delta):
	var error_label_y = 185
	if (direct_connect):
		error_label_y = 210
	error_label.set_position(Vector2(error_label.get_position().x, error_label_y))
