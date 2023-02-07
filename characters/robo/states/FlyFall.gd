extends "res://characters/states/Fall.gd"

func _enter():
	iasa_at = 15

func _tick():
	._tick()
	if host.flying_dir != null:
		
