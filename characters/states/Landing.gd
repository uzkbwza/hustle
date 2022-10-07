extends CharacterState

const DEFAULT_LAG = 4

var lag = 0

func _enter():
	lag = DEFAULT_LAG
	if data is int:
		lag = data
	anim_length = lag
	iasa_at = lag - 1

func _tick():
	host.apply_fric()
	host.apply_forces()
