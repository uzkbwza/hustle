extends SuperMove

const MOVE_DIST = "200"
const BACKWARDS_STALL_FRAMES = 5
const BACKWARDS_STALL_FRAMES_NEUTRAL_EXTRA = 5
const UPWARDS_STALL_FRAMES_NEUTRAL_EXTRA = 5
const EXTRA_FRAME_PER = "1000"
const EXTRA_FRAME_IN_COMBOS = 4
const EXTRA_FRAME_PER_BACKWARDS = "0.2"
const MOMENTUM_FORCE = "16.0"
const CROSS_THROUGH_RECOVERY = 2
const FORWARD_SUPER = 55
const MAX_CROSS_THROUGH_DIST = 32

export var shift = false
export var from_stance = false
export var foresight = false

var backwards_stall_frames = 0
var warp_stall_frames = 0
var starting_dir = 0
var extra_frames = 0
var in_place = false
var forward = false
var x_dist = "0"

func _enter():
	if shift:
		host.load_last_input_into_buffer()
		var prev = _previous_state_name()
		if prev == "LassoPull" or prev == "LassoReel":
			host.opponent.change_state("Grabbed")

func _frame_0():
#	if from_stance:
#		host.start_invulnerability()
	if data == null:
		data = {
			"x": 0,
			"y": 0
		}
	if from_stance:
#		current_tick += 1
		warp_stall_frames = 1
		iasa_at = 6
		data = {
			"x": host.stance_teleport_x,
			"y": host.stance_teleport_y
		}
	starting_dir = host.get_opponent_dir()
	iasa_at = 9
	if state_name == "SpotDodge":
		iasa_at = 10
	backwards_stall_frames = 0
	if !shift:
		host.start_throw_invulnerability()
	var comboing = false
	forward = false
	var scaled = xy_to_dir(data.x, data.y)
	in_place = fixed.lt(fixed.vec_len(scaled.x, scaled.y), "0.1")
	x_dist = fixed.abs(scaled.x)
	next_state_on_hold_on_opponent_turn = false
	
	if super_level > 0:
		host.ex_effect(0)
		var obj = host.obj_from_name(host.cut_projectile)
		if obj:
			obj.disable()

		
	if foresight:
		iasa_at = 7
		warp_stall_frames = 0
		return
	
	if super_level > 0:
		iasa_at = 11 if host.combo_count <= 0 else 8
		backwards_stall_frames = 2
#		starting_iasa_at = iasa_at
#		host.start_invulnerability()
		return
	else:
		if host.opponent.current_state().busy_interrupt_type == BusyInterrupt.Hurt:
			comboing = true

	var dir = xy_to_dir(data.x, data.y, MOVE_DIST)
	var backward = fixed.sign(scaled.x) != host.get_facing_int() and scaled.x != "0"
	if fixed.gt(x_dist, "0.51"):
		if backward:
#			host.add_penalty(10)
#			if !from_stance:
			backwards_stall_frames = BACKWARDS_STALL_FRAMES
			if !comboing:
				backwards_stall_frames += BACKWARDS_STALL_FRAMES_NEUTRAL_EXTRA
		else:
#			host.add_penalty(-5)
			pass
	forward = !(backward or in_place)
	if !comboing and fixed.lt(scaled.y, "-0.2"):
		backwards_stall_frames += UPWARDS_STALL_FRAMES_NEUTRAL_EXTRA
#		host.add_penalty(10)
	extra_frames = fixed.round(fixed.div(fixed.abs(scaled.x), EXTRA_FRAME_PER if !backward else EXTRA_FRAME_PER_BACKWARDS)) + (EXTRA_FRAME_IN_COMBOS if comboing else 0)
	iasa_at += extra_frames
#	print(current_tick)
#	starting_iasa_at = iasa_at

func _frame_3():
	if from_stance:
		host.start_invulnerability()
		host.start_projectile_invulnerability()

func _frame_4():
	host.end_throw_invulnerability()
	if in_place and !foresight and !shift:
		host.start_invulnerability()
	host.start_projectile_invulnerability()
	host.colliding_with_opponent = false

func _frame_5():
	var dir = xy_to_dir(data.x, data.y, MOVE_DIST)
#	host.end_throw_invulnerability()
	if foresight:
		if host.after_image_object != null:
			var obj = host.obj_from_name(host.after_image_object)
			if obj:
				dir = host.obj_local_pos(obj)
				obj.disable()
				host.after_image_object = null
	host.move_directly(dir.x, dir.y)
	var vel = host.get_vel()
	if !shift:
		host.set_vel(vel.x, "0")
	var tele_force = xy_to_dir(data.x, data.y, MOMENTUM_FORCE)
	if fixed.lt(tele_force.y, "0"):
		if host.combo_count <= 0:
			tele_force.y = fixed.mul(tele_force.y, "0.4")
		else:
			tele_force.y = fixed.mul(tele_force.y, "0.666667")
	if forward:
		if host.combo_count <= 0:
			host.gain_super_meter(fixed.round(fixed.mul(str(FORWARD_SUPER), x_dist)))
	host.apply_force(tele_force.x, tele_force.y)
	host.update_data()
	if shift:
		if host.buffered_input["action"] == "Continue":
			host.buffered_input["action"] = _previous_state().fallback_state
			host.release_opponent()
		host.use_buffer()
	
func _frame_6():
	next_state_on_hold_on_opponent_turn = true
	if starting_dir != host.get_opponent_dir() and host.combo_count <= 0 and super_level <= 0 and !foresight and !in_place:
		iasa_at = iasa_at + CROSS_THROUGH_RECOVERY
		var my_pos = host.get_pos()
		var opponent_pos = host.opponent.get_pos()
		var dist = Utils.int_abs(my_pos.x - opponent_pos.x)
		if dist > MAX_CROSS_THROUGH_DIST:
			host.set_pos(opponent_pos.x + MAX_CROSS_THROUGH_DIST * -host.get_opponent_dir(), my_pos.y)
			var vel = host.get_vel()
			host.set_vel(fixed.mul(vel.x, "0.25"), vel.y)
	host.update_facing()

func _frame_7():
	host.end_invulnerability()
	host.end_projectile_invulnerability()
	host.colliding_with_opponent = true

func _tick():
	if from_stance:
		if current_tick == 0:
			current_tick = 4
	if backwards_stall_frames > 0:
		current_tick = 0
		backwards_stall_frames -= 1
	if warp_stall_frames > 0:
		current_tick = 0
		warp_stall_frames -= 1
#	if current_tick > 5:
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	host.set_grounded(host.get_pos().y == 0)

func _exit():
	if shift:
		host.shift()
		host.update_data()
		host.update_facing()

func is_usable():
	if foresight and host.after_image_object == null:
		return false
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel"
