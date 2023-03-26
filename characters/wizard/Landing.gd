extends "res://characters/states/Landing.gd"

func set_lag(lag=null):
	if lag == null:
		if host.fast_fall_landing and host.combo_count <= 0:
			lag = 8
	.set_lag(lag)
