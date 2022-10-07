extends CharacterState

export var speed = "25.0"
export var y_modifier = "1.5"
const SPEED_REDUCTION = "50.0"

func _enter():
#	host.move_directly_relative(0, -)
	var force = xy_to_dir(data["x"], data["y"], speed)
	force.y = fixed_math.mul(force.y, y_modifier)
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
	if host.is_grounded():
		return "Landing"
