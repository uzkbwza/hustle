extends CharacterState

func _enter():
	host.start_invulnerability()

func _tick():
	host.apply_fric()
	host.apply_forces()
	if host.hp <= 0:
		fallback_state = "Knockdown"
