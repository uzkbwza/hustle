extends CharacterState

var hit = false
var tp_pos_x = 0
var tp_pos_y = 0
var tp_vel_x = "0"
var tp_vel_y = "0"
const EXTRA_FRAME_PER_PIXEL = "0.05"

const MIN_LAG_DIST = "200"

const DIST = 16

const max_lag_frames = 8

var lag_frames = 0
var dir = 1

export var teleport = false


func _frame_0():
	host.z_index = -2
	lag_frames = 0
	hit = false

func _frame_5():
	if teleport:
#		host.start_invulnerability()
		var opp_pos = host.opponent.get_pos()
		var opp_pos_local = host.obj_local_center(host.opponent)
		var distance = fixed.vec_len(str(opp_pos_local.x), str(opp_pos_local.y))
		if fixed.gt(distance, MIN_LAG_DIST):
			lag_frames = Utils.int_min(fixed.round(fixed.mul(EXTRA_FRAME_PER_PIXEL, fixed.sub(distance, MIN_LAG_DIST))), max_lag_frames)
		host.colliding_with_opponent = false
		var opp_vel = host.opponent.get_vel()
		tp_pos_x = opp_pos.x + DIST * host.get_opponent_dir()
		dir = host.get_opponent_dir()
		tp_pos_y = opp_pos.y
		tp_vel_x = opp_vel.x
		tp_vel_y = opp_vel.y

func _frame_6():
	if teleport:
#		host.end_invulnerability()
		host.set_vel(tp_vel_x, tp_vel_y)
		host.set_pos(tp_pos_x, tp_pos_y)

func _frame_7():
	if teleport:
		host.set_facing(dir * -1)

func _tick():
	host.apply_fric()
	host.apply_forces()
	if !(teleport and hit):
		host.apply_grav()
	if current_tick >= 8:
		if lag_frames > 0:
			lag_frames -= 1
			current_tick = 8
	elif current_tick > 30:
		host.apply_grav()
		

func _on_hit_something(obj, hitbox):
	hit = true
	._on_hit_something(obj, hitbox)
#	if teleport and obj.is_in_group("Fighter"):
#		if !host.is_grounded():
#			host.reset_momentum()
#			obj.reset_momentum()
