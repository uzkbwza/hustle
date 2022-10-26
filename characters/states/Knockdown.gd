extends CharacterState

func _enter():
	host.start_invulnerability()
	host.colliding_with_opponent = false

func _exit():
	host.colliding_with_opponent = true

func _tick():
	host.apply_fric()
	host.apply_forces()
	if host.hp <= 0:
		endless = true
