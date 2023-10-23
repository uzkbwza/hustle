extends "res://characters/states/Landing.gd"

func _enter():
	._enter()
	host.start_projectile_invulnerability()
