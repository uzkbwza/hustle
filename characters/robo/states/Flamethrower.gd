extends RobotState

func is_usable():
	return .is_usable() and host.can_flamethrower

func process_projectile(_projectile):
	host.can_flamethrower = false
