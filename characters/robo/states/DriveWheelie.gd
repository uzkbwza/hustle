extends RobotState

const X_FRIC = "0.15"
export var boost = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _frame_0():
	if boost:
		host.start_fly_fx()

func _frame_1():
	if boost and host.initiative:
		host.start_invulnerability()

func _frame_6():
	host.end_invulnerability()
	host.stop_fly_fx()

func _tick():
	host.apply_forces_no_limit()
	host.apply_x_fric(X_FRIC)
	if boost:
		host.create_speed_after_image_from_style()

func _frame_11():
	host.big_landing_effect()
