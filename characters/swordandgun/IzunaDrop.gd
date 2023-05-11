extends ThrowState

const LIFT_SPEED = -20
const BACKWARDS_SPEED = 3
const GRAV = "0.9"
const FALL_SPEED = "30"
const SUPER_GAIN = 125

onready var hitbox = $Hitbox

var dir = -1

func _frame_0():
	host.apply_force_relative(-BACKWARDS_SPEED, LIFT_SPEED)
	host.move_directly(0, -1)
	host.z_index = 1


func _tick():
	if current_tick > 1 and host.is_grounded():
		_release()
		activate_hitbox(hitbox)
		spawn_particle_relative(particle_scene)
		queue_state_change("Landing", 40)
		host.opponent.update_facing()
	if current_tick > 10 and current_tick % 8 == 0:
		host.update_data()
		host.move_directly_relative(18, 0)
#		if host.get_facing_int() == dir:
		dir = host.get_opponent_dir()
		if !host.reverse_state:
			dir *= -1
		host.set_facing(dir)
		host.play_sound("IzunaSwish")
	elif current_tick <= 10:
		dir = host.get_facing_int()

	var flip = fixed.gt(host.get_vel().y, "0")
	host.sprite.flip_v = flip
	host.opponent.sprite.flip_v = flip
	host.apply_grav_custom(GRAV, FALL_SPEED)
	host.apply_forces_no_limit()

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	host.gain_super_meter(SUPER_GAIN, "0.35")

func _exit():
	
	host.sprite.flip_v = false
	host.opponent.sprite.flip_v = false
