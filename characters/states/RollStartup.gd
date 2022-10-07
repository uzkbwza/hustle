extends CharacterState

export var speed = "8.5"
export var accel_speed = "0.7"
export var tech = false

var force
var accel


func _enter():
	host.start_invulnerability()
	host.colliding_with_opponent = false
	force = xy_to_dir(data.x, 0, speed, "1")
	accel = xy_to_dir(data.x, 0, accel_speed, "1")
	if "-" in force.x:
		if host.get_facing() == "Right":
			anim_name = "RollBackward"
		else:
			anim_name = "RollForward"
	else:
		if host.get_facing() == "Left":
			anim_name = "RollBackward"
		else:
			anim_name = "RollForward"
	host.apply_force(force.x, str(0))

func _frame_11():
	if !tech:
		host.end_invulnerability()

func _tick():
	host.apply_force(accel.x, str(0))
	host.apply_fric()
	host.apply_forces()
