extends CharacterState

func _enter():
	if data.x * host.get_opponent_dir() < 0:
		return "DashBackward"
	else:
		return "DashForward"

func is_usable():
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel"
