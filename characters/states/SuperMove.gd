extends CharacterState

class_name SuperMove

func is_usable():
	return .is_usable() and host.supers_available > 0

func _enter_shared():
	._enter_shared()
	host.use_super_bar()
