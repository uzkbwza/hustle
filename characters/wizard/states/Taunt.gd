extends "res://characters/states/Taunt.gd"

const FRIC = "0.025"

func _tick():
	host.apply_x_fric(FRIC)
