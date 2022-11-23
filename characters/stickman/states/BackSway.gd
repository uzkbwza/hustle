extends CharacterState

const FORWARD_FORCE = "1.2"

func _frame_0():
	if host.read_advantage:
		host.start_invulnerability()

func _frame_9():
	host.end_invulnerability()

func _tick():
	host.apply_force_relative(FORWARD_FORCE, "0")
