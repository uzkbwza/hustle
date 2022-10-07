extends CharacterState

func _enter():
	if data.x * host.get_facing_int() < 0:
		return "DashBackward"
	else:
		return "DashForward"
