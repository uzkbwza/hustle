extends CharacterState

func _frame_0():
	host.start_invulnerability()
	host.colliding_with_opponent = true
#
#func _tick():
#	host.apply_fric()
#	host.apply_forces()

func _exit():
	host.start_wakeup_throw_immunity()
