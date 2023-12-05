extends CharacterState

class_name BeastState

export var moving_up_only = false
export var moving_down_only = false
export var force_air_juke = false

func _enter_shared():
	._enter_shared()
	pass

func is_usable():
	if !.is_usable():
		return false
	if host.install_ticks == 0 and (moving_up_only or moving_down_only):
		var vel = host.get_vel()
		var is_moving_down = host.fixed.ge(vel.y, "0")
		var is_moving_up = host.fixed.lt(vel.y, "0")
		if moving_down_only and !is_moving_down:
			return false
		if moving_up_only and !is_moving_up:
			return false
	return true

func get_interrupt_from():
	if interrupt_from == []:
		return []
	var extras = []
	if host.install_ticks > 0:
		extras.append("Grounded")
		extras.append("Aerial")
	return interrupt_from + extras
