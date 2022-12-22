extends CharacterState

export var dir_x = 1
export var dash_speed = 100
export var fric = "0.05"
export var spawn_particle = true
export var startup_lag = 0
export var stop_frame = 0
export var back_penalty = 5

func _enter():
	if startup_lag != 0 or stop_frame != 0:
		interruptible_on_opponent_turn = false
	else:
		interruptible_on_opponent_turn = true

func _frame_1():
	if dir_x < 0:
		host.add_penalty(back_penalty)
	if startup_lag != 0:
		return
	host.apply_force_relative(dir_x * dash_speed, 0)
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
