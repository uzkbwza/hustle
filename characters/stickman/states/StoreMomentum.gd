extends CharacterState

#export var release = false
const STORE_MODIFIER = "0.90"

#const RELEASE_MODIFIER = "1.35"

func _frame_1():
#	if !release:
		var vel = host.get_vel()
		host.stored_momentum_x = fixed.add(host.stored_momentum_x, fixed.mul(fixed.abs(vel.x), STORE_MODIFIER))
		host.stored_momentum_y = fixed.add(host.stored_momentum_y, fixed.mul(fixed.abs(vel.y), STORE_MODIFIER))
		var speed = fixed.vec_len(host.stored_momentum_x, host.stored_momentum_y)
		var stored_speed = speed

#		print(host.stored_speed)
		host.reset_momentum()
		host.momentum_stores = 1
#		if host.momentum_stores > 3:
#			host.momentum_stores = 3
#		match host.momentum_stores:
#			1:
		host.stored_speed_1 = stored_speed
#			2:
#				host.stored_speed_2 = stored_speed
#			3:
#				host.stored_speed_3 = stored_speed
#		if fixed.lt(host.stored_momentum_y, "0"):
#			host.stored_momentum_y = fixed.mul(host.stored_momentum_y, "0.5")
#	else:
#		host.reset_momentum()
#		host.momentum_stores -= 1
#		host.set_vel(fixed.mul(fixed.mul(host.stored_momentum_x, RELEASE_MODIFIER), str(host.get_facing_int())), fixed.mul(host.stored_momentum_y, RELEASE_MODIFIER))

func _tick():
#	if !release:
		host.apply_fric()
		host.apply_grav()
		host.apply_forces()
#	else:
#		host.apply_forces_no_limit()

func is_usable():
#	if !release:
#		return .is_usable() and !host.storing_momentum
	return .is_usable() and (host.momentum_stores < 3 or host.infinite_resources)




