extends CharacterState

export var speed = "8.5"
export var accel_speed = "0.7"
export var tech = false

var force
var accel


func _enter():
	host.used_air_dodge = true
	force = xy_to_dir(data.x, 0, speed, "1")
	accel = xy_to_dir(data.x, 0, accel_speed, "1")
	if "-" in force.x:
		if host.get_facing() == "Right":
			anim_name = "RollBackward"
			force.x = fixed.mul(force.x, "0.3")
		else:
			anim_name = "RollForward"
	else:
		if host.get_facing() == "Left":
			anim_name = "RollBackward"
			force.x = fixed.mul(force.x, "0.3")
		else:
			anim_name = "RollForward"
	host.apply_force(force.x, str(0))

func _frame_0():
	if tech:
		host.start_invulnerability()
		host.colliding_with_opponent = false
	host.start_throw_invulnerability()
	host.start_projectile_invulnerability()

func _frame_1():
	host.colliding_with_opponent = false

func _frame_2():
	host.start_invulnerability()

func _frame_10():
	if !tech:
		host.end_invulnerability()
		host.end_throw_invulnerability()
		host.end_projectile_invulnerability()

func _tick():
	host.colliding_with_opponent = false
	if accel:
		host.apply_force(accel.x, str(0))
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()

func is_usable():
	if !host.is_grounded():
		return .is_usable() and !host.used_air_dodge
	return .is_usable()
