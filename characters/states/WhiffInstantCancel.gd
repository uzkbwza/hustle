extends "res://characters/states/InstantCancel.gd"

func _enter():
	spawn_particle_relative(preload("res://fx/InstantCancelEffect.tscn"), host.hurtbox_pos_relative_float())
	host.use_burst_meter(host.MAX_BURST_METER)

func is_usable():
	var has_meter = host.bursts_available > 0
	var usable = !host.got_parried and has_meter
	return usable
