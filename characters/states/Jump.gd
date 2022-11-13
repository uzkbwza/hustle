extends CharacterState

const SPEED_REDUCTION = "50.0"

export var speed = "25.0"
export var y_modifier = "1.5"
export var x_speed_preserved = "0.25"
export var super_jump = false

const SHORT_HOP_IASA = 7
const FULL_HOP_IASA = 14

var jump_tick = 1
var squat
var force_x
var force_y

func jump():
	var vel = host.get_vel()
	host.set_vel(fixed.mul(vel.x, x_speed_preserved), "0")
	var force = xy_to_dir(data["x"], data["y"], speed)
	if !super_jump:
		spawn_particle_relative(particle_scene, Vector2(), Vector2(float(force.x), float(force.y)))
	else:
		spawn_particle_relative(preload("res://characters/stickman/StompEffect.tscn"))
		var camera = host.get_camera()
		if camera:
			camera.bump(Vector2.UP, 10, 20 / 60.0)
	force.y = fixed.mul(force.y, y_modifier)
	host.apply_force(force.x, force.y)
	force_x = force.x
	force_y = force.y

func _frame_4():
	if squat and !super_jump:
		jump()

func _frame_12():
	if super_jump:
		jump()

func _enter():
	var vec = xy_to_dir(data["x"], data["y"], "1")
	var length = fixed.vec_len(vec.x, vec.y)
	var full_hop = fixed.gt(length, "0.7")
	squat = super_jump or (air_type == AirType.Grounded and fixed.sign(str(data["x"])) != host.get_facing_int() and data["x"] != 0 and full_hop)
	
	if !squat:
		jump_tick = 1
		jump()
	else:
		jump_tick = 4 if !super_jump else 12
		anim_name = "Landing"

	if !super_jump:
		if squat:
			interrupt_frames[0] = 18
			interrupt_frames[1] = 29
		elif full_hop:
			interrupt_frames[0] = 14
			interrupt_frames[1] = 25
		else:
			interrupt_frames[0] = 7
			interrupt_frames[1] = 18
	sfx_tick = jump_tick
#	host.move_directly_relative(0, -)

func _tick():
	if current_tick >= interrupt_frames[0]:
		if !super_jump:
			interruptible_on_opponent_turn = true
	if current_tick >= jump_tick:
		if "-" in force_x:
			if host.get_facing() == "Right":
				anim_name = "JumpBack"
			else:
				anim_name = sprite_animation
		else:
			if host.get_facing() == "Left":
				anim_name = "JumpBack"
			else:
				anim_name = sprite_animation
		host.apply_grav()
		if !super_jump:
			host.apply_forces()
		else:
			host.apply_forces_no_limit()
	if current_tick > jump_tick:
		if host.is_grounded():
			return "Landing"
	else:
		interruptible_on_opponent_turn = false
