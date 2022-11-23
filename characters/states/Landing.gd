extends CharacterState

const DEFAULT_LAG = 4

var lag = 0

func set_lag(lag=null):
	if lag == null:
		lag = DEFAULT_LAG
	if data is int:
		lag = data
	anim_length = lag
	iasa_at = lag - 1

func _frame_0():
	set_lag(null)

func _tick():
	if current_tick > 4:
		host.apply_fric()
	host.apply_forces()
