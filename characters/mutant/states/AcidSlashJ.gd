extends BeastState

const FORWARD_X_FORCE = "13"
const FORWARD_Y_FORCE = "-13"
const UP_X_FORCE = "5"
const UP_Y_FORCE = "-16"
const AIR_MODIFIER = "0.75"
const GROUND_MODIFIER = "0.85"

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
	host.apply_force_relative(fixed.mul(FORWARD_X_FORCE if !up else UP_X_FORCE, AIR_MODIFIER if !host.is_grounded() else GROUND_MODIFIER), fixed.mul(FORWARD_Y_FORCE if !up else UP_Y_FORCE, AIR_MODIFIER if !host.is_grounded() else GROUND_MODIFIER))
#	host.end_aerial_attack_invulnerability()
