extends CharacterState

export var dir_x = 1
export var dash_speed = 100
export var fric = "0.05"

func _enter():
	host.apply_force_relative(dir_x * dash_speed, 0)

func _tick():
	host.apply_full_fric(fric)
	host.apply_forces()
