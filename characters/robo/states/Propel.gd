extends RobotState

const FRICTION_TICKS = 20
const GROUND_FRICTION = "0.2"
const FORCE = "1"


func _enter():
	next_state_on_hold = !host.buffer_drive_cancel
#	fallback_state = "Wait" if !host.buffer_drive_cancel else "Drive"

func _frame_0():
	host.chara.set_ground_friction(GROUND_FRICTION)
	host.propel_friction_ticks = FRICTION_TICKS
	host.start_fly_fx()


func _exit():
	host.stop_fly_fx()

func _tick():
	if current_tick > 3:
		host.apply_force_relative(FORCE, "0")
