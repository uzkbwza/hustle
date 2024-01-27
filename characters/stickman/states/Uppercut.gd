extends CharacterState

onready var hitbox_2 = $Hitbox2

func _frame_0():
#	if current_tick == 0:
	if host.initiative and host.is_grounded():
#		host.start_invulnerability()
		host.start_invulnerability()
#	host.start_throw_invulnerability()
#	if !host.is_grounded():
#		host.start_projectile_invulnerability()
	var vel = host.get_vel()
	if air_type != AirType.Aerial:
		if fixed.sign(vel.x) != host.get_facing_int():
			host.reset_momentum()
		else:
			host.reset_momentum()
			host.set_vel(fixed.div(vel.x, "3"), vel.y)
#	host.start_invulnerability()
	hitbox_2.block_punishable = false

func on_got_blocked():
	hitbox_2.block_punishable = true

func _tick():
	host.apply_grav()
	host.apply_forces()
	if host.is_grounded() and current_tick > force_tick:
		return "UppercutLanding"

func _frame_4():
	host.end_invulnerability()
#	host.end_projectile_invulnerability()

func _frame_8():
	host.end_throw_invulnerability()

func _frame_9():
	host.end_invulnerability()
