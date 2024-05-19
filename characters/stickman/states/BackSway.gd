extends CharacterState

const FORWARD_FORCE = "1.2"

func _enter():
	if host.is_grounded():
		host.reset_momentum()


func _frame_2():
	if host.initiative:
		host.start_invulnerability()

func _frame_9():
	host.end_invulnerability()

func _tick():
	host.apply_force_relative(FORWARD_FORCE, "0")
