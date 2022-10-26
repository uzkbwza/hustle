extends CharacterState

class_name SuperMove

export var super_level = 1
export var supers_used = -1

func is_usable():
	return .is_usable() and host.supers_available >= super_level

func _enter_shared():
	._enter_shared()
	for i in range(super_level if supers_used == -1 else supers_used):
		host.use_super_bar()
