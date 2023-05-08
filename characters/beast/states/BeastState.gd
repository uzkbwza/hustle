extends CharacterState

class_name BeastState

export var moving_up_only = false
export var moving_down_only = false

func is_usable():
	if !.is_usable():
		return false
	if moving_up_only or moving_down_only:
		var vel = host.get_vel()
		var is_moving_down = host.fixed.gt(vel.y, "0")
		if moving_down_only and !is_moving_down:
			return false
		if moving_up_only and is_moving_down:
			return false
	return true
