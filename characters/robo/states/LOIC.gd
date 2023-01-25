extends RobotState

const MIN_AIM_TICKS = 20
const MAX_AIM_TICKS = 85

func _enter():
	host.loic_draining = true
	host.can_loic = false

func process_projectile(obj):
	obj.set_pos(host.opponent.get_pos().x, 0)
	var t = data.x
	t = fixed.div(str(t), "100")
	t = fixed.mul(t, str(MAX_AIM_TICKS - MIN_AIM_TICKS))
	t = fixed.add(t, str(MIN_AIM_TICKS))
	obj.aim_ticks = fixed.round(t)
	host.orbital_strike_out = true
	host.orbital_strike_projectile = obj.obj_name

func is_usable():
	return .is_usable() and !host.orbital_strike_out and host.can_loic
