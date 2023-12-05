extends ObjectState

export var disable_when_this_far_from_terrain = 10
export var speed = "16.0"
export var launch = true
export var bounces = 0
export var bounce_multiplier = "-0.9"
export var launch_in_movement_direction = true
var can_floor_bounce = true
var floor_bounce_ticks = 0

onready var hitbox = $Hitbox

func _enter():
	var can_floor_bounce = true
	host.reset_momentum()
	host.launched = true
	if launch:
		var force = fixed.vec_mul(data.x, data.y, speed)
		host.apply_force(force.x, force.y)
		host.set_facing(1)
#		host.movable = false
	else:
		host.stop_particles()

func _tick():
	var pos = host.get_pos()
	var vel = host.get_vel()
	if floor_bounce_ticks > 0:
		floor_bounce_ticks -= 1
	if fixed.gt(vel.y, "0") and floor_bounce_ticks == 0:
		can_floor_bounce = true
	if current_tick > 3:
		if pos.y > -disable_when_this_far_from_terrain and can_floor_bounce:
			if bounces > 0:
				bounces -= 1
				host.play_sound("Bounce")
				host.set_vel(vel.x, fixed.mul(vel.y, bounce_multiplier))
				host.set_pos(pos.x, -disable_when_this_far_from_terrain)
				can_floor_bounce = false
				floor_bounce_ticks = 3
			else:
				host.disable()
		elif host.stage_width - Utils.int_abs(pos.x) < disable_when_this_far_from_terrain:
			if bounces > 0:
				bounces -= 1
				host.play_sound("Bounce")
				host.set_vel(fixed.mul(vel.x, bounce_multiplier), vel.y)
			else:
				host.disable()
		elif host.has_ceiling and Utils.int_abs(-host.ceiling_height - pos.y) < disable_when_this_far_from_terrain:
			host.disable()

	if launch_in_movement_direction:
		vel = host.get_vel()
		var movement_dir = fixed.normalized_vec(vel.x, vel.y)
		hitbox.dir_x = movement_dir.x
		hitbox.dir_y = movement_dir.y

	if launch:
		host.apply_forces_no_limit()
		host.limit_speed(speed)

func _on_hit_something(obj, hitbox):
	if obj.is_in_group("Fighter"):
		host.hit_action(obj)
		host.disable()
	._on_hit_something(obj, hitbox)
