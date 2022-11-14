extends "res://characters/states/Fall.gd"

var apply_lift = true

func _frame_0():
	apply_lift = false
	host.reset_momentum()
	if !host.used_aerial_h_slash:
		apply_lift = true
		host.used_aerial_h_slash = true

func _frame_5():
	if apply_lift:
		var force = fixed.normalized_vec_times("1.0", "-0.75", "9.0")
		host.apply_force_relative(force.x, force.y)
	else:
		var force = fixed.normalized_vec_times("1.0", "0.0", "8.0")
		host.apply_force_relative(force.x, force.y)
