extends "res://characters/states/Landing.gd"

#const MAX_EXTRA_LAG_FRAMES = 3

func set_lag(lag=null):
#	if lag == null:
#		if host.fast_fall_landing and host.combo_count <= 0:
#			lag = 4 + Utils.int_max(MAX_EXTRA_LAG_FRAMES - _previous_state().current_tick, 0)
	.set_lag(lag)
