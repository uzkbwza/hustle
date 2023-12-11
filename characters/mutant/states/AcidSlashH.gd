extends BeastState

const FORCE_SPEED = "10"

var force_speed_ = FORCE_SPEED


func _frame_0():
	force_speed_ = FORCE_SPEED if !host.is_neutral_juke() else "0"

func _frame_10():
	host.apply_force_relative(force_speed_, "0")
