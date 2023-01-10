extends SuperMove

const MOVE_DIST = "200"
const BACKWARDS_STALL_FRAMES = 5
const BACKWARDS_STALL_FRAMES_NEUTRAL_EXTRA = 5
const UPWARDS_STALL_FRAMES_NEUTRAL_EXTRA = 5
const EXTRA_FRAME_PER = "0.45"
const EXTRA_FRAME_IN_COMBOS = 4
const EXTRA_FRAME_PER_BACKWARDS = "0.2"
const MOMENTUM_FORCE = "16.0"

var backwards_stall_frames = 0


func _frame_0():
	iasa_at = 9
	backwards_stall_frames = 0
	host.start_throw_invulnerability()
	var comboing = false
	if super_level > 0:
		iasa_at = 7
#		host.start_invulnerability()
		return
	else:
		if host.opponent.current_state().busy_interrupt_type == BusyInterrupt.Hurt:
			comboing = true
	var dir = xy_to_dir(data.x, data.y, MOVE_DIST)
	var scaled = xy_to_dir(data.x, data.y)
	var backwards = fixed.sign(scaled.x) != host.get_facing_int() and scaled.x != "0"
	if fixed.gt(fixed.abs(scaled.x), "0.5"):
		if backwards:
			backwards_stall_frames = BACKWARDS_STALL_FRAMES
			if !comboing:
				backwards_stall_frames += BACKWARDS_STALL_FRAMES_NEUTRAL_EXTRA
	if !comboing and fixed.lt(scaled.y, "-0.2"):
		backwards_stall_frames += UPWARDS_STALL_FRAMES_NEUTRAL_EXTRA
	
	iasa_at += fixed.round(fixed.div(fixed.abs(scaled.x), EXTRA_FRAME_PER if !backwards else EXTRA_FRAME_PER_BACKWARDS)) + (EXTRA_FRAME_IN_COMBOS if comboing else 0)

func _frame_4():
	host.end_throw_invulnerability()
	host.start_invulnerability()
	host.start_projectile_invulnerability()
	host.colliding_with_opponent = false

func _frame_5():
	var dir = xy_to_dir(data.x, data.y, MOVE_DIST)
	host.end_throw_invulnerability()
	host.move_directly(dir.x, dir.y)
	var vel = host.get_vel()
	host.set_vel(vel.x, "0")
	var tele_force = xy_to_dir(data.x, data.y, MOMENTUM_FORCE)
	if fixed.lt(tele_force.y, "0"):
		tele_force.y = fixed.mul(tele_force.y, "0.666667")
	host.apply_force(tele_force.x, tele_force.y)
	host.update_data()

func _frame_6():
	host.update_facing()

func _frame_7():
	host.end_invulnerability()
	host.colliding_with_opponent = true

func _tick():
	if backwards_stall_frames > 0:
		current_tick = 0
		backwards_stall_frames -= 1
#	if current_tick > 5:
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	host.set_grounded(host.get_pos().y == 0)

func is_usable():
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel"
