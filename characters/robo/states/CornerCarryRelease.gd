extends ThrowState

const BACKWARD_MOMENTUM = "-1.35"
const BACKWARD_IMPULSE = "-200"

func _frame_6():
	host.apply_force_relative(BACKWARD_IMPULSE, "0")

func _tick():
	if current_tick < 15 and current_tick > 6:
		host.apply_force_relative(BACKWARD_MOMENTUM, "0")
