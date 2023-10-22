extends BeastState

func _tick():
	if current_tick > 4 and current_tick < 12:
		host.move_directly_relative(3, 0)

func _frame_4():
	host.start_projectile_invulnerability()

func _frame_13():
	host.end_projectile_invulnerability()
