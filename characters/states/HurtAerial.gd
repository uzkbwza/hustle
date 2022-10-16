extends CharacterHurtState

const AIR_FRIC = "0.015"
const DI_STRENGTH = "1.0"

var hitbox
var hitstun = 0
var knockdown = false
var can_act

func _enter():
	can_act = false
	var hitbox = data["hitbox"]
	knockdown = hitbox.knockdown
	hitstun = hitbox.hitstun_ticks
	var x = fixed.mul(hitbox.dir_x, "-1" if hitbox.facing == "Left" else "1")
	var knockback_force = fixed.normalized_vec_times(x, hitbox.dir_y, hitbox.knockback)

	var di_force = fixed.vec_mul(host.current_di.x, host.current_di.y, DI_STRENGTH)
	var force_x = fixed.add(knockback_force.x, di_force.x)
	var force_y = fixed.add(knockback_force.y, di_force.y)
	host.apply_force(force_x, force_y)
	host.move_directly(0, -1)

func _tick():
	host.apply_full_fric(AIR_FRIC)
	host.apply_grav()
	host.apply_forces_no_limit()
	if current_tick > 5:
		if host.is_grounded():
			if knockdown or host.hp == 0:
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
