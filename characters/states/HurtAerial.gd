extends CharacterHurtState

const AIR_FRIC = "0.015"
const HIT_GRAV = "0.25"
const HIT_FALL_SPEED = "15.0"

const BOUNCE_FRAMES = 4

const DI_STRENGTH = "2.0"


var hitstun = 0
var knockdown = false
var can_act
var bounce_frames = 0

func _enter():
	can_act = false
	bounce_frames = 0
	knockdown = hitbox.knockdown
	hitstun = hitbox.hitstun_ticks + (COUNTER_HIT_ADDITIONAL_HITSTUN_FRAMES if hitbox.counter_hit else 0)
	counter = hitbox.counter_hit
	if hitbox.ground_bounce and host.is_grounded() and fixed.gt(hitbox.dir_y, "0"):
		hitbox.dir_y = fixed.mul(hitbox.dir_y, "-1")
		bounce_frames = BOUNCE_FRAMES
	var x = get_x_dir(hitbox)
	var knockback_force = fixed.normalized_vec_times(x, hitbox.dir_y, hitbox.knockback)
	
	host.set_facing(Utils.int_sign(fixed.round(x)) * -1)
	var di_force = fixed.vec_mul(host.current_di.x, host.current_di.y, DI_STRENGTH)
	var force_x = fixed.add(knockback_force.x, di_force.x)
	var force_y = fixed.add(knockback_force.y, di_force.y)
	host.apply_force(force_x, force_y)
	host.move_directly(0, -1)

func _tick():
	if host.is_grounded() and bounce_frames > 0:
		anim_name = "Knockdown"
	else:
		anim_name = "HurtAerial"

	host.apply_x_fric(AIR_FRIC)
	host.apply_grav_custom(HIT_GRAV, HIT_FALL_SPEED)
	host.apply_forces_no_limit()
	
	if bounce_frames > 0:
		host.set_pos(host.get_pos().x, 0)
		bounce_frames -= 1
		if bounce_frames == 0:
			host.set_pos(host.get_pos().x, -1)
	else:
		if host.is_grounded() and fixed.ge(host.get_vel().y, "0"):
			if knockdown or host.hp == 0:
#				host.start_invulnerability()
				return "Knockdown"
			else:
				return "Landing"
				
	var extended_hitstun = hitbox.knockdown_extends_hitstun and hitbox.knockdown
	
	if !extended_hitstun and current_tick > hitstun:
		if can_act:
			return fallback_state
		else:
			enable_interrupt()
			can_act = true
