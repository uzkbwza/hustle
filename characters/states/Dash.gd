extends CharacterState

const MIN_IASA = 7
const MAX_IASA = 14
const MIN_SPEED_RATIO = "0.25"

export var dir_x = 1
export var dash_speed = 100
export var fric = "0.05"
export var spawn_particle = true
export var startup_lag = 0
export var stop_frame = 0
export var back_penalty = 5
var updated = false

var dist_ratio = "1.0"

func _enter():
	updated = false

func _frame_1():
	if dir_x < 0:
		host.add_penalty(back_penalty)
	else:
		dist_ratio = fixed.add(fixed.div(str(data.x), "100"), "0.0")
		starting_iasa_at = Utils.int_max(fixed.round(fixed.add(fixed.mul(dist_ratio, str(MAX_IASA - MIN_IASA)), str(MIN_IASA))), 1)
		iasa_at = starting_iasa_at
#		print(iasa_at)
	if startup_lag != 0:
		return
	host.apply_force_relative(fixed.mul(str(dir_x * dash_speed), fixed.add(fixed.mul(dist_ratio, fixed.sub("1.0", MIN_SPEED_RATIO)), MIN_SPEED_RATIO)), "0")
	if spawn_particle:
		spawn_particle_relative(preload("res://fx/DashParticle.tscn"), host.hurtbox_pos_relative_float(), Vector2(dir_x, 0))

func _tick():
	host.apply_x_fric(fric)
	host.apply_forces()
	if startup_lag > 0 and current_tick == startup_lag:
		host.apply_force_relative(dir_x * dash_speed, 0)
		if spawn_particle:
			spawn_particle_relative(preload("res://fx/DashParticle.tscn"), host.hurtbox_pos_relative_float(), Vector2(dir_x, 0))
#		interruptible_on_opponent_turn = true
	if stop_frame > 0 and current_tick == stop_frame:
		host.reset_momentum()
	if dir_x > 0 and !updated and host.opponent.colliding_with_opponent and !host.opponent.is_in_hurt_state():
		var vel = host.get_vel()
		if !fixed.eq(vel.x, "0") and fixed.sign(vel.x) != host.get_opponent_dir():
			host.update_facing()
			updated = true
			host.set_vel(fixed.mul(fixed.abs(vel.x), str(host.get_opponent_dir())), vel.y)
