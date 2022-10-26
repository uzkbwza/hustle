extends CharacterState

export var speed_modifier_amount = "10.0"

var speed_modifier

func _frame_1():
	if data:
		speed_modifier = fixed.round(fixed.mul(fixed.sub(fixed.div(str(data.x), "100"), "0.5"), speed_modifier_amount))
	host.apply_force_relative(speed_modifier, 0)

func _tick():
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()
	if current_tick > 2 and host.is_grounded():
		return "Landing"
