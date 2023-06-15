extends CharacterState

const GRAB_DISTANCE = "16"
const PULL_SPEED = "-15"

var grabbed = false

onready var throw_box = $ThrowBox

func _frame_0():
	grabbed = false

func _frame_1():
	var opp_pos = host.obj_local_center(host.opponent)
	throw_box.activate()
	throw_box.x = opp_pos.x * host.get_facing_int()
	throw_box.y = opp_pos.y

func _tick():
	grabbed = false
	var opp_pos = host.obj_local_center(host.opponent)
	throw_box.x = opp_pos.x * host.get_facing_int()
	throw_box.y = opp_pos.y
	if current_tick > 1 and fixed.lt(fixed.vec_len(str(opp_pos.x), str(opp_pos.y)), GRAB_DISTANCE):
		grabbed = true
		return "IzunaDrop"
	else:
		opp_pos = host.obj_local_pos(host.opponent)
		var opp_move_vec = fixed.normalized_vec_times(str(opp_pos.x), str(opp_pos.y), PULL_SPEED)
		var global_opp_pos = host.opponent.get_pos()
		global_opp_pos.x = fixed.round(fixed.add(opp_move_vec.x, str(global_opp_pos.x)))
		global_opp_pos.y = fixed.round(fixed.add(opp_move_vec.y, str(global_opp_pos.y)))
		host.opponent.set_pos(global_opp_pos.x, global_opp_pos.y)
		if host.objs_map.has(host.lasso_projectile):
			host.objs_map[host.lasso_projectile].set_pos(global_opp_pos.x, global_opp_pos.y - 16)

func _exit():
	if host.objs_map.has(host.lasso_projectile):
		host.objs_map[host.lasso_projectile].disable()
		host.lasso_projectile = null
	if !grabbed:
		host.opponent.state_machine.queue_state("Wait")
