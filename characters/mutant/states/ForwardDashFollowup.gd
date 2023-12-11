extends BeastState

func _enter():
	host.update_facing()

func apply_enter_force():
	if data and Utils.int_sign(data.x) != host.get_facing_int():
		return
	.apply_enter_force()

func _frame_0():
	if data and Utils.int_sign(data.x) != host.get_facing_int():
		if host.get_facing_int() == fixed.sign(host.get_vel().x):
			host.reset_momentum()
		return "ForwardDashBackFollowup"
	host.start_projectile_invulnerability()
	apply_grav = false

func _frame_6():
	host.end_projectile_invulnerability()
	apply_grav = true
