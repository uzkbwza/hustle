extends BeastState

const MOVE_X = "2.0"

func _tick():
	if current_tick < 13:
		host.move_directly_relative(MOVE_X, "0")

		host.create_speed_after_image_from_style()
