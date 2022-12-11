extends CharacterState

var apply_lift = true

func _frame_0():
	apply_lift = false
	
	if !host.used_aerial_h_slash:
		apply_lift = true
		host.used_aerial_h_slash = true

func _frame_5():
	var vel = host.get_vel()
	vel = fixed.vec_mul(vel.x, vel.y, "0.5")
	host.set_vel(vel.x, vel.y)
	if apply_lift:
		var force = fixed.normalized_vec_times("1.0", "-0.75", "9.0")
		host.apply_force_relative(force.x, force.y)
	else:
		var force = fixed.normalized_vec_times("1.0", "0.0", "8.0")
		host.apply_force_relative(force.x, force.y)

func _tick():
	if current_tick > 6:
		if host.is_grounded():
			return "Landing"
