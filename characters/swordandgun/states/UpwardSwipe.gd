extends CharacterState

export var GROUNDED_LIFT = "-15.0"
export var AERIAL_LIFT = "-8.0"


func _frame_7():
	var vel = host.get_vel()
	host.set_vel(vel.x, "0")
	host.apply_force_relative("0", GROUNDED_LIFT if host.is_grounded() else AERIAL_LIFT)

func _tick():
	if current_tick > 6:
		host.apply_grav()
