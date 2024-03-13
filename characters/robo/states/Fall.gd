extends "res://characters/states/Fall.gd"

func _enter():
	iasa_at = 11

func _tick():
	._tick()
	if host.flying_dir != null:
		iasa_at = 10
		if current_tick > 0 and current_tick % 10 == 0:
			enable_interrupt()
	if current_tick > 1 and host.is_grounded():
		return "Landing"
