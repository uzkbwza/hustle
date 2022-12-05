extends CharacterHurtState

const AIR_FRIC = "0.015"
const HIT_GRAV = "0.25"
const HIT_FALL_SPEED = "15.0"

const BOUNCE_FRAMES = 4

const DI_STRENGTH = "2.0"

enum BOUNCE {
	LEFT_WALL,
	RIGHT_WALL,
	NO_BOUNCE
}

var hitstun = 0
var knockdown = false
var can_act
var bounce_frames = 0


const BOUNCE_FACTOR = "-0.85"
const BOUNCE_PARTICLE = preload("res://fx/LandingParticle.tscn")

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

	var vel = host.get_vel()
	var bounce = BOUNCE.NO_BOUNCE
	var col_box = host.get_collision_box()
	
	if (host.hitlag_ticks > 0 or (host.is_grounded() and bounce_frames > 0)):
		pass
	elif (col_box.x1 <= -host.stage_width and fixed.lt(vel.x, "0")):
		bounce = BOUNCE.LEFT_WALL
	elif (col_box.x2 >= host.stage_width and fixed.gt(vel.x, "0")):
		bounce = BOUNCE.RIGHT_WALL

	if (bounce != BOUNCE.NO_BOUNCE):
		host.hitlag_ticks = 3
		host.play_sound("Block")
		host.set_vel(fixed.mul(vel.x, BOUNCE_FACTOR), vel.y)
		
		# Only show the effect if the velocity is decent
		if (Vector2(vel.x, vel.y).length() > 5):
			var particle_pos = Vector2(
				(col_box.x1 if bounce == BOUNCE.LEFT_WALL else col_box.x2),
				host.get_center_position_float().y
			)
			
			var particle_dir = Vector2.DOWN if bounce == BOUNCE.LEFT_WALL else Vector2.UP
			
			host.spawn_particle_effect(BOUNCE_PARTICLE, particle_pos, particle_dir)

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
