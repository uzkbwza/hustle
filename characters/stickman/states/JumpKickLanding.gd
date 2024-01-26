extends "res://characters/states/Landing.gd"

func _enter():
	._enter()
	if _previous_state().get("had_invuln"):
		host.start_projectile_invulnerability()
