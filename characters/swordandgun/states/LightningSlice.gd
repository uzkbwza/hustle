extends CharacterState

const TRACKING_DISTANCE = "86.0"

const DEFAULT_HITBOX_X = 128
const DEFAULT_HITBOX_Y = -16

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var cancel = false

onready var hitbox = $Hitbox

func _frame_1():
	var vel = host.get_vel()
	host.set_vel(vel.x, "0")

#func _frame_6():

func _frame_8():
#	spawn_particle_relative(preload("res://characters/swordandgun/LightningSliceEffect.tscn"), Vector2(hitbox.x * host.get_facing_int(), hitbox.y), Vector2.RIGHT * host.get_facing_int())
	spawn_particle_relative(particle_scene)

func _tick():
	var tracking_pos = {
		"x": DEFAULT_HITBOX_X,
		"y": DEFAULT_HITBOX_Y,
	}
	hitbox.x = DEFAULT_HITBOX_X
	hitbox.y = DEFAULT_HITBOX_Y
	tracking_pos.x *= host.get_facing_int()
	var host_pos = host.get_pos()
	tracking_pos.x += host_pos.x
	tracking_pos.y += host_pos.y
	var enemy_local_pos = host.obj_local_center(host.opponent)
	var enemy_pos = host.opponent.get_hurtbox_center()
	if fixed.lt(fixed.vec_dist(str(tracking_pos.x), str(tracking_pos.y), str(enemy_pos.x), str(enemy_pos.y)), TRACKING_DISTANCE):
		hitbox.x = Utils.int_abs(enemy_local_pos.x)
		hitbox.y = enemy_local_pos.y -16

func _tick_after():
	._tick_after()
	if cancel and current_tick == 1:
		current_tick = 3
	if current_tick > 16:
		host.apply_grav()
