extends CharacterState
#
#func _frame_0():
#	if host.initiative:
#		host.start_invulnerability()
#
#func _frame_4():
#	host.end_invulnerability()
var move = true

func _frame_0():
	move = !(_previous_state_name() == "ImpaleTeleport" and host.reverse_state)


func _frame_2():
	if move:
		host.apply_force_relative("-14.0", "0")
