extends CharacterState

class_name CounterAttack

enum CounterType {
	High,
	Low,
	Grab,
}

export(CounterType) var counter_type = CounterType.High

var bracing = false

func _enter():
	bracing = true
	host.use_burst_meter(fixed.round(fixed.mul(str(host.MAX_BURST_METER), "0.33")))

func init():
	.init()
	is_brace = true
	pass

func _tick():
	anim_name = "ParryHigh" if host.is_grounded() and counter_type != CounterType.Low else "ParryLow"
	if host.is_grounded():
		host.apply_x_fric(HurtGrounded.GROUND_FRIC)
	else:
		host.apply_x_fric(HurtAerial.AIR_FRIC)
		host.apply_grav_custom(HurtAerial.HIT_GRAV, HurtAerial.HIT_FALL_SPEED)
	host.apply_forces_no_limit()

func is_usable():
	if !(host.bursts_available > 0 or host.burst_meter >= fixed.round(fixed.mul(str(host.MAX_BURST_METER), "0.33"))):
		return false
	if !.is_usable():
		return false
	if host.current_state() is CharacterHurtState:
		if host.current_state().hitbox.counter_hit:
			return false
	return true
