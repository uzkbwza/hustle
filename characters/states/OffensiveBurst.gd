extends CharacterState

var started_falling = false

func _enter():
	host.use_burst()
	host.start_projectile_invulnerability()
	host.update_grounded()
	started_falling = false
	host.start_invulnerability()

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

func is_usable():
	return host.burst_enabled and (host.hit_fighter_last() or host.combo_count > 0) and (host.bursts_available > 0) and .is_usable()

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj and obj.is_in_group("Fighter"):
		host.burst_cancel_combo = true
