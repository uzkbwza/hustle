extends CharacterState

var moving_down = false

func _frame_0():
	moving_down = false
	var vel = host.get_vel()
	if fixed.gt(vel.y, "0"):
		vel.y = "0"
	host.set_vel(vel.x, vel.y)
	var force = fixed.normalized_vec_times("0.5", "-1", "3")
	host.move_directly(0, -8)
	host.apply_force_relative(force.x, force.y)

func _frame_9():
	moving_down = true

func _tick():
	if moving_down:
		host.apply_force(0, 5)
		host.move_directly(0, 10)
	host.apply_grav()
	
