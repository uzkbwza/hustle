extends CharacterState

func is_usable():
	return .is_usable() and host.has_gun
