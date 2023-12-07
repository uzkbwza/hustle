extends CharacterState

const MIN_IASA = 7
const MIN_NEUTRAL_IASA = 9
const MAX_IASA = 14
const MIN_SPEED_RATIO = "0.5"
var MAX_SPEED_RATIO = "1.25"

export var dir_x = 1
export var dash_speed = 100
export var dash_speed_string = "0"
export var fric = "0.05"
export var spawn_particle = true
export var startup_lag = 0
export var stop_frame = 0
export var back_penalty = 5
export var air = false

export var speed_limit = "40"
var updated = false
var charged = false
var auto = false
var dash_force = "0"

var dist_ratio = "1.0"

func _enter():
	updated = false
	charged = false
	if data:
		if data.has("Distance"):
			auto = data.AutoCorrect
			data = data.Distance

func get_velocity_forward_meter_gain_multiplier():
	return fixed.mul(velocity_forward_meter_gain_multiplier, dist_ratio)

func _frame_0():
	if dir_x < 0:
		host.start_throw_invulnerability()

func _frame_1():
	if dir_x < 0:
		MAX_SPEED_RATIO = "1.0"
		host.add_penalty(back_penalty)
		host.reset_momentum()
	else:
		MAX_SPEED_RATIO = "1.25"
		beats_backdash = true
		dist_ratio = fixed.add(fixed.div(str(data.x), "100"), "0.0")
		var min_iasa = MIN_IASA if host.combo_count > 0 else MIN_NEUTRAL_IASA
#		starting_iasa_at = 
		if !charged and host.combo_count > 0:
			starting_iasa_at = min_iasa
		else:
			starting_iasa_at = Utils.int_max(fixed.round(fixed.add(fixed.mul(dist_ratio, str(MAX_IASA - min_iasa)), str(min_iasa))), 1)
#		print(iasa_at)
		iasa_at = starting_iasa_at
	if startup_lag != 0:
		return
	var dash_force = str(dir_x * dash_speed) if dash_speed_string == "0" else fixed.mul(str(dir_x), dash_speed_string)
#	dash_force = "8"
	if _previous_state_name() == "ChargeDash" or (data and data.has("charged")):
		if dir_x >= 0:
			charged = true
			if (data and data.has("charged")):
				data["charged"] = true
			dash_force = fixed.mul(dash_force, "2")
	host.apply_force_relative(fixed.mul(dash_force, fixed.add(fixed.mul(dist_ratio, fixed.sub(MAX_SPEED_RATIO, MIN_SPEED_RATIO)), MIN_SPEED_RATIO)), "0")
	if spawn_particle:
		spawn_particle_relative(preload("res://fx/DashParticle.tscn"), host.hurtbox_pos_relative_float(), Vector2(dir_x, 0))
	if !air:
		host.apply_grav()

func get_hold_restart():
	if air:
		if host.air_movements_left > 0:
			return "AirDashForward"
		return "Fall"
	return ""

func spawn_dash_particle():
	spawn_particle_relative(preload("res://fx/DashParticle.tscn"), host.hurtbox_pos_relative_float(), Vector2(dir_x, 0))

func _frame_7():
	if dir_x < 0:
		host.end_throw_invulnerability()

func _tick():
	host.apply_x_fric(fric)
	if !air:
		host.apply_grav()
	if charged:
		host.apply_forces_no_limit()
	else:
		host.apply_forces()
	host.limit_speed(speed_limit)
	var repeated = _previous_state() and _previous_state_name() == name
	if (startup_lag > 0 and current_tick == startup_lag) and !repeated:
		host.apply_force_relative(dash_force, "0")
		if spawn_particle:
			spawn_particle_relative(preload("res://fx/DashParticle.tscn"), host.hurtbox_pos_relative_float(), Vector2(dir_x, 0))
#		interruptible_on_opponent_turn = true
#	if stop_frame > 0 and current_tick == stop_frame and !repeated:
#		host.reset_momentum()

	if auto and dir_x > 0 and host.opponent.colliding_with_opponent and !host.opponent.is_in_hurt_state() and current_tick % 4 == 0:
		host.update_data()
		var vel = host.get_vel()
		if !fixed.eq(vel.x, "0") and fixed.sign(vel.x) != host.get_opponent_dir():
			host.update_facing()
			updated = true
			host.set_vel(fixed.mul(fixed.abs(vel.x), str(host.get_opponent_dir())), vel.y)
