extends "res://characters/states/InstantCancel.gd"

func _enter():
	host.use_burst_meter(host.MAX_BURST_METER / 2)

func is_usable():
	var has_meter = host.burst_meter > host.MAX_BURST_METER / 2 or host.bursts_available > 0
	var usable = !host.got_parried and has_meter
	return usable
