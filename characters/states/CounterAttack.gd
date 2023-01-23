extends CharacterState

export var counter_state_ground: String = "Wait"
export var counter_state_air: String = "Fall"

func _enter():
	pass

func is_usable():
	return .is_usable() and host.can_counter_attack
