extends WizardState

const VEL_MODIFIER = "15.0"

func get_projectile_pos():
	var x = fixed.round(fixed.add(str(host.opponent.get_pos().x), fixed.mul(host.opponent.get_vel().x, VEL_MODIFIER)))
	return { "x": x, "y": 0 }

func process_projectile(_projectile):
	host.can_vile_clutch = false

func is_usable():
	return .is_usable() and host.can_vile_clutch
