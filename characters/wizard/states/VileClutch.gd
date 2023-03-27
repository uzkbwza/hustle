extends WizardState

#const VEL_MODIFIER = "15.0"
const MAX_DISTANCE = "500"

func get_projectile_pos():
#	var x = fixed.round(fixed.add(str(host.opponent.get_pos().x), fixed.mul(host.opponent.get_vel().x, VEL_MODIFIER)))
	var x = xy_to_dir(data.x, 0).x
	x = fixed.round(fixed.mul(x, MAX_DISTANCE)) * host.get_facing_int() + host.get_pos().x
	return { "x": x, "y": 0 }

func process_projectile(_projectile):
	host.can_vile_clutch = false

func is_usable():
	return .is_usable() and host.can_vile_clutch
