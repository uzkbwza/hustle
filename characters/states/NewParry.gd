extends ParryState

class_name GroundedParryState

const IS_NEW_PARRY = true


export var push = false
export var autoguard = false
export var disable_aerial_movement = false
#export var real_parry = false

var _disable_aerial_movement
var punishable = false
#var whiffed_block = false setget , get_whiffed_block
export var reblock = false

var extra_iasa = 0
var parried_last = false

func _ready():
	_disable_aerial_movement = disable_aerial_movement

func get_whiffed_block():
#	print()
#	print(parried)
#	print(autoguard)
#	print(host.combo_count <= 0)
#	print(_previous_state().state_name if _previous_state() else "no previous")
	var prev = _previous_state()
	if prev and prev.get("IS_NEW_PARRY"):
		return (!prev.parried_last and !prev.autoguard and host.combo_count <= 0)
	return false
	
func _enter():
	if data == null:
		data = { "Melee Parry Timing": {"count" : 0}, "Block Height": { "x": 1, "y": 0}}
	extra_iasa = 0
	if disable_aerial_movement:
		interrupt_exceptions.append("AerialMovement")
	start()

func get_hold_restart():
	if get_whiffed_block():
		return "ParryAfterWhiff"
	else:
		return "ParryHigh"

func get_last_action_text() -> String:
	if push:
		return ""
	return ("%sf" % data["Melee Parry Timing"].count) if !reblock else ""

func start():
	started_in_combo = host.combo_count > 0
	endless = false
	perfect = true
	parry_type = initial_parry_type
	parry_type = ParryHeight.High if data["Block Height"].y == 0 else ParryHeight.Low
	parry_active = true
	parry_tick = 0
	parried = false
	interruptible_on_opponent_turn = host.combo_count <= 0
	anim_length = 20 + extra_iasa
	iasa_at = -1
	host.blocked_hitbox_plus_frames = 0
#	host.add_penalty(10, true)
	if host.is_grounded():
		anim_name = "ParryHigh" if data["Block Height"].y == 0 else "ParryLow"
	else:
		anim_name = "ParryLow"
#	host.blockstun_ticks = 0

func _frame_0():
	start()
#	host.whiffed_block = get_whiffed_block()
	if !(_previous_state() and _previous_state().get("IS_NEW_PARRY")) or _previous_state() == null:
		punishable = false

func is_usable():
	var current = host.current_state()
	var whiffed_block_last = false
	if current and current.get("IS_NEW_PARRY"):
		whiffed_block_last = (!current.parried and !current.autoguard and host.combo_count <= 0)
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel" and \
	(whiffed_block_last if reblock else !whiffed_block_last)

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
		disable_aerial_movement = false
		interrupt_exceptions.erase("AerialMovement")
		enable_interrupt()
		host.set_block_stun(0)
		host.blocked_hitbox_plus_frames = 0
	else:
		parry_type = ParryHeight.Both
		host.start_throw_invulnerability()
	host.parried = true
	parried = true
	parried_last = true
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
	if started_in_combo and host.combo_count <= 0:
		return false

	return true
	
func _tick():
#	interruptible_on_opponent_turn = !started_in_combo
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
	parried_last = parried
	host.blocked_last_hit = false
#	host.whiffed_block = get_whiffed_block()

func enable_interrupt(check_opponent=true, remove_hitlag=false):
	.enable_interrupt(check_opponent, remove_hitlag)

func opponent_turn_interrupt():
	.opponent_turn_interrupt()
