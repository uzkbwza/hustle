extends CharacterState

func _tick():
	if data.x * host.get_opponent_dir() < 0:
		return "DashBackward"
	else:
		return "DashForward"
