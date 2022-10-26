extends CharacterState

export var dir_x = 1
export var dash_speed = 100
export var fric = "0.05"
export var spawn_particle = true

func _frame_1():
	host.apply_force_relative(dir_x * dash_speed, 0)
	if spawn_particle:
		spawn_particle_relative(preload("res://fx/DashParticle.tscn"), Vector2(0, -16), Vector2(dir_x, 0))

func _tick():
	host.apply_full_fric(fric)
	host.apply_forces()
