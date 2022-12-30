extends CharacterState

const TRACKING_DISTANCE = "86.0"
const DEADZONE_RADIUS = "70.0"

const DEFAULT_HITBOX_X = 128
const DEFAULT_HITBOX_Y = -16

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var cancel = false
export var followup = false

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
	if followup:
		 hitbox.x = host.lightning_slice_x
		 hitbox.y = host.lightning_slice_y
#	if tracking:
#		tracking_pos.x *= host.get_facing_int()
#		var host_pos = host.get_pos()
#		tracking_pos.x += host_pos.x
#		tracking_pos.y += host_pos.y
#		var enemy_local_pos = host.obj_local_center(host.opponent)
#		var enemy_pos = host.opponent.get_hurtbox_center()
##		var in_deadzone = fixed.lt(fixed.vec_len(str(enemy_local_pos.x), str(enemy_local_pos.y)), DEADZONE_RADIUS)
#		var in_tracking_radius = fixed.lt(fixed.vec_dist(str(tracking_pos.x), str(tracking_pos.y), str(enemy_pos.x), str(enemy_pos.y)), TRACKING_DISTANCE)
##		if !in_deadzone:
#		if in_tracking_radius:
#			hitbox.x = Utils.int_abs(enemy_local_pos.x)
#			hitbox.y = enemy_local_pos.y -16
#		if in_deadzone:
#			hitbox.x = DEFAULT_HITBOX_X
#			hitbox.y = DEFAULT_HITBOX_Y
	else:
		var hitbox_pos = xy_to_dir(data.x, data.y, TRACKING_DISTANCE)
		hitbox.x = DEFAULT_HITBOX_X + (fixed.round(hitbox_pos.x) * host.get_facing_int())
		hitbox.y = DEFAULT_HITBOX_Y + fixed.round(hitbox_pos.y)
		host.lightning_slice_x = hitbox.x
		host.lightning_slice_y = hitbox.y
#	if hitbox.y > 0:
#		hitbox.y = 0

func _tick_after():
	._tick_after()
	if cancel and current_tick == 1:
		current_tick = 3
	if current_tick > 16:
		host.apply_grav()
