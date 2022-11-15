extends "res://characters/states/InstantCancel.gd"

func _enter():
	host.use_burst_meter(500)

func is_usable():
	var has_meter = host.burst_meter > host.MAX_BURST_METER / 3 or host.bursts_available > 0
	var usable = !host.got_parried and has_meter
	return usable
