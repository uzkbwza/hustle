extends CharacterState

func is_usable():
	if Network.multiplayer_active and host.id != Network.pid:
		return false
	return Global.forfeit_buttons_enabled

func _enter():
	host.forfeit()
