extends CharacterState

export var release = false

const RELEASE_MODIFIER = "1.35"

func _frame_1():
	if !release:
		var vel = host.get_vel()
		host.stored_momentum_x = vel.x
		host.stored_momentum_y = vel.y
		host.stored_speed = fixed.vec_len(vel.x, vel.y)
		host.reset_momentum()
		host.storing_momentum = true
#		if fixed.lt(host.stored_momentum_y, "0"):
#			host.stored_momentum_y = fixed.mul(host.stored_momentum_y, "0.5")
	else:
		host.reset_momentum()
		host.storing_momentum = false
		host.set_vel(fixed.mul(fixed.mul(host.stored_momentum_x, RELEASE_MODIFIER), str(host.get_facing_int())), fixed.mul(host.stored_momentum_y, RELEASE_MODIFIER))

func _tick():
	if !release:
		host.apply_fric()
		host.apply_grav()
		host.apply_forces()
	else:
		host.apply_forces_no_limit()

func is_usable():
	if !release:
		return .is_usable() and !host.storing_momentum
	return .is_usable() and host.storing_momentum
