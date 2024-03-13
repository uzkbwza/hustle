extends BeastState

const FORWARD_X_FORCE = "17"
const FORWARD_Y_FORCE = "-13"
const UP_X_FORCE = "5"
const UP_Y_FORCE = "-16"

export var up = false

func _enter():
	if data and data.x == 0:
		return "AcidSlashJUp"

#func _frame_0():
#	if host.initiative and host.is_grounded():
#		host.start_aerial_attack_invulnerability()

func _frame_9():
	host.set_vel(host.get_vel().x, "0")
	host.move_directly(0, -1)
	host.apply_force_relative(FORWARD_X_FORCE if !up else UP_X_FORCE, FORWARD_Y_FORCE if !up else UP_Y_FORCE)
#	host.end_aerial_attack_invulnerability()
