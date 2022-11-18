extends CharacterState


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var cancel = false

onready var hitbox = $Hitbox

func _frame_1():
	var vel = host.get_vel()
	host.set_vel(vel.x, "0")

func _frame_6():
	spawn_particle_relative(preload("res://characters/swordandgun/LightningSliceEffect.tscn"), Vector2(hitbox.x * host.get_facing_int(), hitbox.y), Vector2.RIGHT * host.get_facing_int())

func _frame_8():
	spawn_particle_relative(particle_scene)

func _tick_after():
	._tick_after()
	if cancel and current_tick == 1:
		current_tick = 3
	if current_tick > 16:
		host.apply_grav()
