extends CharacterState

const SPEED_REDUCTION = "50.0"

export var speed = "25.0"
export var y_modifier = "1.5"
export var x_speed_preserved = "0.25"
export var super_jump = false
export var super_jump_speed_override = ""

export var fall_anim = false
export var fall_anim_speed = "1"

const SHORT_HOP_IASA = 7
const FULL_HOP_IASA = 14
const FULL_HOP_LENGTH = "0.7"
const SUPER_JUMP_SPEED = "17.0"
const BASE_JUMP_SPEED = "0.5"
const SUPER_JUMP_FORCES_END_TICK = 25



var jump_tick = 1
var squat
var force_x
var force_y

func jump():
	var vel = host.get_vel()
	host.set_vel(fixed.mul(vel.x, x_speed_preserved), "0")
	var force = xy_to_dir(data["x"], data["y"])
	var force_power = fixed.vec_mul(force.x, force.y, fixed.powu(fixed.vec_len(force.x, force.y), 2))
	force = FixedVec2String.new(fixed.div(fixed.add(force_power.x, force.x), "2"), fixed.div(fixed.add(force_power.y, force.y), "2"))
	force = fixed.vec_mul(force.x, force.y, fixed.add(speed, BASE_JUMP_SPEED) if !super_jump else (SUPER_JUMP_SPEED if super_jump_speed_override == "" else super_jump_speed_override))
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

func _frame_7():
	if super_jump:
		jump()

func _frame_0():
	var vec = xy_to_dir(data["x"], data["y"], "1")
	var length = fixed.vec_len(vec.x, vec.y)
	var full_hop = fixed.gt(length, FULL_HOP_LENGTH)
	squat = super_jump or (air_type == AirType.Grounded and fixed.sign(str(data["x"])) != host.get_facing_int() and data["x"] != 0 and full_hop)
	
	if !squat:
		jump_tick = 1
		jump()
	else:
		jump_tick = 4 if !super_jump else 7
		anim_name = "Landing"

	if !super_jump:
		if squat:
			interrupt_frames[0] = 14
			interrupt_frames[1] = 25
		elif full_hop:
			interrupt_frames[0] = 10
			interrupt_frames[1] = 21
		else:
			interrupt_frames[0] = 7
			interrupt_frames[1] = 18
	sfx_tick = jump_tick
#	host.move_directly_relative(0, -)

func _tick():
	if current_tick >= interrupt_frames[0]:
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
		if fall_anim:
			if fixed.gt(host.get_vel().y, fall_anim_speed):
				anim_name = "Fall"
		host.apply_grav()
		if !super_jump or fixed.gt(host.get_vel().y, "0") or current_tick > SUPER_JUMP_FORCES_END_TICK:
			host.apply_forces()
		else:
			host.apply_forces_no_limit()
	if current_tick > jump_tick:
		if host.is_grounded():
			return "Landing"
	else:
		interruptible_on_opponent_turn = false
