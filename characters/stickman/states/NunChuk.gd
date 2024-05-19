extends CharacterState

export var heavy = false

func on_got_perfect_parried():
	if heavy:
		host.hitlag_ticks += 4

#func _tick():
#	host.apply_fric()
#	host.apply_forces()
#
#func _tick():
#	host.apply_fric()
#	host.apply_forces()
