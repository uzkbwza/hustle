extends CharacterState

export var defensive = false

var started_falling = false

func _enter():
	host.start_invulnerability()
	host.start_projectile_invulnerability()
	interruptible_on_opponent_turn = false
	host.opponent.reset_combo()
	started_falling = false
	host.use_burst()

func _frame_15():
	host.end_invulnerability()
	started_falling = true

func _tick():
	if started_falling:
		host.apply_grav()
	host.apply_forces()
	if current_tick > 15:
		host.end_invulnerability()
	else:
		host.start_invulnerability()

func _exit():
	host.end_projectile_invulnerability()

func is_usable():
	return host.burst_enabled and .is_usable() and (host.bursts_available > 0)

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj.is_in_group("Fighter"):
		if defensive:
			host.opponent.start_invulnerability()
			if host.initiative:
				host.gain_super_meter((host.MAX_SUPER_METER * 5) / 3)
