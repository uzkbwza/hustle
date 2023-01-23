extends RobotState

const X_FRIC = "0.15"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _tick():
	host.apply_forces_no_limit()
	host.apply_x_fric(X_FRIC)

func _frame_11():
	host.big_landing_effect()
