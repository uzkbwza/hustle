extends RobotState

const MIN_AIM_TICKS_GALVANIZE = 20
const MIN_AIM_TICKS = 14
const MAX_AIM_TICKS = 85

export var self_ = false

func _enter():
	host.loic_draining = true
	host.can_loic = false
	self_ = data.Self


func process_projectile(obj):
	obj.set_pos(host.opponent.get_pos().x if !self_ else host.get_pos().x, 0)
	var t = data.Delay.x
	t = fixed.div(str(t), "100")
	var min_ = MIN_AIM_TICKS_GALVANIZE if self_ else MIN_AIM_TICKS
	t = fixed.mul(t, str(MAX_AIM_TICKS - min_))
	t = fixed.add(t, str(min_))
	obj.aim_ticks = fixed.round(t)
	host.orbital_strike_out = true
	host.orbital_strike_projectile = obj.obj_name
	obj.self_ = self_

func is_usable():
 
	return .is_usable() and !host.orbital_strike_out and host.can_loic
