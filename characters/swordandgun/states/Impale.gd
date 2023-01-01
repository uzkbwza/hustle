extends CharacterState

var hit = false
var tp_pos_x = 0
var tp_pos_y = 0
var tp_vel_x = "0"
var tp_vel_y = "0"

const DIST = 16

export var teleport = false

func _frame_0():
	host.z_index = -2
	hit = false

func _frame_6():
	if teleport:
		host.start_invulnerability()
		var opp_pos = host.opponent.get_pos()
		host.colliding_with_opponent = false
		var opp_vel = host.opponent.get_vel()
		tp_pos_x = opp_pos.x + DIST * host.get_opponent_dir()
		tp_pos_y = opp_pos.y
		tp_vel_x = opp_vel.x
		tp_vel_y = opp_vel.y

func _frame_7():
	if teleport:
		host.end_invulnerability()
		host.set_vel(tp_vel_x, tp_vel_y)
		host.set_pos(tp_pos_x, tp_pos_y)

func _frame_8():
	if teleport:
		host.update_facing()

func _tick():
	host.apply_fric()
	host.apply_forces()
	if !(teleport and hit):
		host.apply_grav()
	elif current_tick > 30:
		host.apply_grav()
		

func _on_hit_something(obj, hitbox):
	hit = true
	._on_hit_something(obj, hitbox)
#	if teleport and obj.is_in_group("Fighter"):
#		if !host.is_grounded():
#			host.reset_momentum()
#			obj.reset_momentum()
