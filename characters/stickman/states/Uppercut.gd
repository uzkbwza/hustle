extends CharacterState
#
func _frame_0():
#	if current_tick == 0:
	if host.read_advantage:
		host.start_invulnerability()
	var vel = host.get_vel()
	if fixed.sign(vel.x) != host.get_facing_int():
		host.reset_momentum()
	else:
		host.reset_momentum()
		host.set_vel(fixed.div(vel.x, "3"), vel.y)
#	host.start_invulnerability()

func _tick():
	host.apply_grav()
	host.apply_forces()
	if host.is_grounded() and current_tick > force_tick:
		return "UppercutLanding"

func _frame_4():
	host.end_invulnerability()
