extends BeastState

const TRACKING_SPEED = 7
const MIN_TRACKING_SPEED = 40

var starting_dir = 0
var tracking = false
var tracked_yet = false

func _frame_0():
	tracking = false
	tracked_yet = false
#	host.disable_collisions()
	host.colliding_with_opponent = false
	apply_grav = false
	starting_dir = host.get_opponent_dir()
	pass

#func _frame_4():
#	host.set_vel(fixed.mul(host.get_vel().x, "0.85"), "0")

func _frame_15():
	host.set_vel(fixed.mul(host.get_vel().x, "0.15"), "0")

func _frame_6():
	host.turn_around()

func _tick():
	var vel = host.get_vel()
	var opp_dist = Utils.int_abs(host.obj_local_pos(host.opponent).x)
	if current_tick > 3 and current_tick < 12 and !tracked_yet:
		if host.get_opponent_dir() != starting_dir and opp_dist >= MIN_TRACKING_SPEED:
			tracking = true
			tracked_yet = true
			host.set_vel(vel.x, "0")
			host.update_data()
			vel = host.get_vel()
	if tracking and opp_dist >= MIN_TRACKING_SPEED:
#		host.move_directly(host.get_opponent_dir() * TRACKING_SPEED, 0)
		host.set_vel(str(-starting_dir * TRACKING_SPEED), vel.y)
		if host.get_opponent_dir() == starting_dir:
			tracking = false

func _frame_10():
	host.colliding_with_opponent = true
	pass


func _frame_13():
	apply_grav = true

func _on_hit_something(obj, hitbox):
	tracking = false
	host.set_vel(fixed.mul(host.get_vel().x, "0.75"), "0")

func _got_parried():
	host.set_vel(fixed.mul(host.get_vel().x, "0.75"), "0")
