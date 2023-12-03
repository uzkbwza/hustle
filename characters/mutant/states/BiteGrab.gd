extends BeastState

const MOVE_X = "2.0"

const BACK_LAG = 5

var back_lag = 0

func _enter():
	back_lag = 0
	if host.reverse_state:
		back_lag = BACK_LAG

func _tick():
	if back_lag > 0:
		back_lag -= 1
		current_tick = 0
	if current_tick < 13:
		host.move_directly_relative(MOVE_X, "0")

		host.create_speed_after_image_from_style()
