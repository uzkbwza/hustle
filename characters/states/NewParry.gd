extends ParryState

class_name GroundedParryState

const IS_NEW_PARRY = true


export var push = false
export var autoguard = false

var punishable = false

func _enter():
	if data == null:
		data = { "Melee Parry Timing": {"count" : 0}, "Block Height": { "x": 1, "y": 0}}

	if (!_previous_state().get("IS_NEW_PARRY") and !autoguard):
		host.blockstun_ticks = 0
	if _previous_state().get("IS_NEW_PARRY") and _previous_state().autoguard:
		parry_active = true
	elif _previous_state().get("IS_NEW_PARRY") and _previous_state().push:
		parry_active = true
	elif autoguard:
		parry_active = true

func _frame_0():

	started_in_combo = host.combo_count > 0
	endless = false
	perfect = true
	parry_type = initial_parry_type
	parry_type = ParryHeight.High if data["Block Height"].y == 0 else ParryHeight.Low
	parry_active = true
	parry_tick = 0
	parried = false
	interruptible_on_opponent_turn = host.combo_count <= 0
	punishable = false
	anim_length = 20
	iasa_at = - 1
	host.blocked_hitbox_plus_frames = 0
	host.add_penalty(10, true)
	if host.is_grounded():
		anim_name = "ParryHigh" if data["Block Height"].y == 0 else "ParryLow"
	else:
		anim_name = "ParryLow"
	host.blockstun_ticks = 0

func is_usable():
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel"

func on_continue():
	punishable = true

func _frame_10():
	pass

func matches_hitbox_height(hitbox, parry_type=null):
	if push:
		return true
	if parry_type == null:
		parry_type = self.parry_type
	match hitbox.hit_height:
		Hitbox.HitHeight.High:
			return parry_type == ParryHeight.High or parry_type == ParryHeight.Both
		Hitbox.HitHeight.Mid:
			return parry_type == ParryHeight.High or parry_type == ParryHeight.Both
		Hitbox.HitHeight.Low:
			return parry_type == ParryHeight.Low or parry_type == ParryHeight.Both
	return false

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
	if punishable:
		return false
	if not perfect:
		return true
	if hitbox == null:
		return false
	if not active:
		return false
	if not parry_active:
		return false
	return true
	
func _tick():
	if !parried and !autoguard:
			host.set_block_stun(1)
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
	if current_tick == 4 and host.opponent.current_state().get("IS_NEW_PARRY"):
		enable_interrupt()

func _exit():
	parry_active = false
	host.blocked_last_hit = false
