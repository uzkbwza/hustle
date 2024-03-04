extends CharacterState

export var move_speed = "10"

func _frame_1():
	spawn_particle_relative(preload("res://fx/DashParticle.tscn"), host.hurtbox_pos_relative_float(), Vector2(0, 1))

func _tick():
	host.move_directly("0", move_speed)
