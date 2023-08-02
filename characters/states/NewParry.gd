extends ParryState

class_name GroundedParryState

export var push = false

func _frame_0():
	host.end_throw_invulnerability()
	if data == null:
		data = { "count" : 0 }
	started_in_combo = host.combo_count > 0
	endless = false
	perfect = true
	parry_type = initial_parry_type
	parry_active = true
	parry_tick = 0
	parried = false
	interruptible_on_opponent_turn = true
	anim_length = 20
	iasa_at = - 1
	host.add_penalty(10, true)
	if host.is_grounded():
		anim_name = "ParryHigh"
	else:
		anim_name = "ParryLow"

func is_usable():
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel"

func _frame_10():
	pass

func parry(perfect = true):
	perfect = perfect and can_parry
	if perfect:
		enable_interrupt()
	else:
		parry_type = ParryHeight.Both
		host.start_throw_invulnerability()
	host.parried = true
	parried = true
	self.perfect = perfect

func can_parry_hitbox(hitbox):
	if not perfect:
		return true
	if hitbox == null:
		return false
	if not active:
		return false
	if not parry_active:
		return false

	match hitbox.hit_height:
		Hitbox.HitHeight.High:
			return parry_type == ParryHeight.High or parry_type == ParryHeight.Both
		Hitbox.HitHeight.Mid:
			return parry_type == ParryHeight.High or parry_type == ParryHeight.Both
		Hitbox.HitHeight.Low:
			return parry_type == ParryHeight.Low or parry_type == ParryHeight.Both
	return false

func _tick():
	host.apply_fric()
#	if air_type == AirType.Aerial:
	host.apply_grav()
	if host.combo_count > 0:
		if current_tick > 60 and parried:
			enable_interrupt()
			return fallback_state
	host.apply_forces()
#	host.parry_chip_divisor = host.PARRY_CHIP_DIVISOR / (1 + abs(current_tick - data.x + 1) * 0.2)
	host.parry_knockback_divisor = host.PARRY_GROUNDED_KNOCKBACK_DIVISOR


func _exit():
	parry_active = false
	host.blocked_last_hit = false
