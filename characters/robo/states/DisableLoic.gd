extends RobotState

func _enter():
	var obj = host.obj_from_name(host.orbital_strike_projectile)
	if obj:
		obj.deactivate()

func is_usable():
	var usable = false
	var obj = host.obj_from_name(host.orbital_strike_projectile)
	if obj and !obj.deactivating:
		usable = true
	return .is_usable() and usable
