extends "res://characters/states/InstantCancel.gd"

func _enter():
	spawn_particle_relative(preload("res://fx/InstantCancelEffect.tscn"), host.hurtbox_pos_relative_float())
	host.prediction_effect()
	host.use_burst_meter(fixed.round(fixed.mul(str(host.MAX_BURST_METER), "0.75")))

func is_usable():
	var has_meter = host.bursts_available > 0 or host.burst_meter >= fixed.round(fixed.mul(str(host.MAX_BURST_METER), "0.75"))
#	print(host.burst_meter)
#	print(fixed.round(fixed.mul(str(host.MAX_BURST_METER), "0.75")))
	var usable = !host.got_parried and !host.got_blocked and has_meter
	return usable
