extends CharacterState

const MIN_SPEED = "3"
const MAX_SPEED = "14"

func _frame_0():
	var amount = fixed.div(str(data.x), "100")
	amount = fixed.lerp_string(MIN_SPEED, MAX_SPEED, amount)
	host.apply_force_relative(amount, "0")
#	host.apply_force_relative(fixed.mul(SPEED, fixed.div(str(data.x), "100")), "0")
