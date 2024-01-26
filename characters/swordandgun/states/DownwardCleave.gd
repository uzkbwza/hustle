extends CharacterState

export var jump_speed = "3"
export var grounded = false

var moving_down = false
var grounded_frames = 0

func _enter():
	grounded_frames = 0
	if !grounded and host.is_grounded():
		grounded = true

func _frame_0():
	if grounded:
		grounded_frames = 2
		return

	moving_down = false
	var vel = host.get_vel()
	if fixed.gt(vel.y, "0"):
		vel.y = "0"
	host.set_vel(vel.x, vel.y)
	var force = fixed.normalized_vec_times("0.5", "-1", jump_speed)
	host.move_directly(0, -8)
	entered_in_air = !host.is_grounded()
	host.apply_force_relative(force.x, force.y)

func _frame_1():
	if grounded:
		if grounded_frames > 0:
			return
		moving_down = false
		var vel = host.get_vel()
		if fixed.gt(vel.y, "0"):
			vel.y = "0"
		host.set_vel(vel.x, vel.y)
		var force = fixed.normalized_vec_times("0.5", "-1", jump_speed)
		host.move_directly(0, -8)
		host.apply_force_relative(force.x, force.y)

func _frame_9():
	if !grounded:
		moving_down = true

func _frame_11():
	if grounded:
		moving_down = true

func _tick():
	if grounded_frames > 0:
		current_tick = 0
		grounded_frames -= 1
	if moving_down:
		host.apply_force(0, 5)
		host.move_directly(0, 10)
	host.apply_grav()
