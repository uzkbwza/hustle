extends CharacterState

const SPEED_REDUCTION = "50.0"
export var speed = "25.0"
export var y_modifier = "1.5"
export var x_speed_preserved = "0.25"

func _enter():
#	host.move_directly_relative(0, -)
	var vel = host.get_vel()
	host.set_vel(fixed.mul(vel.x, x_speed_preserved), "0")
	var force = xy_to_dir(data["x"], data["y"], speed)
	spawn_particle_relative(particle_scene, Vector2(), Vector2(float(force.x), float(force.y)))
	force.y = fixed.mul(force.y, y_modifier)
	host.apply_force(force.x, force.y)
	if "-" in force.x:
		if host.get_facing() == "Right":
			anim_name = "JumpBack"
		else:
			anim_name = sprite_animation
	else:
		if host.get_facing() == "Left":
			anim_name = "JumpBack"
		else:
			anim_name = sprite_animation

func _tick():
	host.apply_grav()
	host.apply_forces()
	if current_tick > 1:
		if host.is_grounded():
			return "Landing"
