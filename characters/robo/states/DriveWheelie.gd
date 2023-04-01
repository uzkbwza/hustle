extends RobotState

const X_FRIC = "0.15"
export var boost = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _frame_0():
	if boost:
		host.start_invulnerability()
		host.start_fly_fx()

func _frame_6():
	host.end_invulnerability()
	host.stop_fly_fx()

func _tick():
	host.apply_forces_no_limit()
	host.apply_x_fric(X_FRIC)

func _frame_11():
	host.big_landing_effect()
