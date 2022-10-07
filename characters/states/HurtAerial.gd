extends CharacterHurtState

const AIR_FRIC = "0.015"

var hitbox
var hitstun = 0
var knockdown = false
var can_act

func _enter():
	can_act = false
	hitbox = data["hitbox"]
	knockdown = hitbox.knockdown
	hitstun = hitbox.hitstun_ticks
	var force = fixed_math.normalized_vec_times(hitbox.dir_x, hitbox.dir_y, hitbox.knockback)
	force.x = fixed_math.mul(force.x, "-1" if hitbox.facing == "Left" else "1")
	host.apply_force(force.x, force.y)
	host.move_directly(0, -1)

func _tick():
	host.apply_full_fric(AIR_FRIC)
	host.apply_grav()
	host.apply_forces_no_limit()
	if current_tick > 5:
		if host.is_grounded():
			if knockdown:
#				host.start_invulnerability()
				return "Knockdown"
			else:
				return "Landing"

	if !knockdown and current_tick > hitstun:
		if can_act:
			return fallback_state
		else:
			enable_interrupt()
			can_act = true
