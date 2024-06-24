extends CharacterHurtState

class_name HurtAerial

const AIR_FRIC = "0.015"
const HIT_GRAV = "0.25"
const HIT_FALL_SPEED = "15.0"

const BOUNCE_FRAMES = 4

const DI_STRENGTH = "2.0"

var hitstun = 0
var knockdown = false
var wall_slam = false
var hard_knockdown = false
var can_act
var bounce_frames = 0
var ground_bounced = false

const BOUNCE_FACTOR = "-0.85"
const BOUNCE_PARTICLE = preload("res://fx/LandingParticle.tscn")

func begin_ground_bounce():
	hitbox.dir_y = fixed.mul(hitbox.dir_y, "-1")
	hitbox.knockback = fixed.mul(hitbox.knockback, hitbox.ground_bounce_knockback_modifier)
	bounce_frames = BOUNCE_FRAMES
	ground_bounced = true
	host.play_sound("HitBass")
	host.play_sound("GroundBounce")

func _exit():
	bounce_frames = 0

func _enter():
	ground_bounced = false
	can_act = false

	knockdown = hitbox.knockdown
	hard_knockdown = hitbox.hard_knockdown
	wall_slam = hitbox.wall_slam and host.wall_slams < host.MAX_WALL_SLAMS
#	hitstun = hitbox.hitstun_ticks + hitstun_modifier(hitbox)
	hitstun = global_hitstun_modifier(hitbox.hitstun_ticks + hitstun_modifier(hitbox))
#	print(hitstun)
	counter = hitbox.counter_hit
	if counter:
		host.opponent.counterhit_this_turn = true

	if (hitbox.ground_bounce and host.is_grounded()) and fixed.gt(hitbox.dir_y, "0"):
		begin_ground_bounce()
	
	var x = get_x_dir(hitbox)
	var y = hitbox.dir_y

	if hitbox.vacuum:
		var vacuum_dir = get_vacuum_dir(hitbox)
		x = vacuum_dir.x
		y = vacuum_dir.y
	elif hitbox.send_away_from_center:
		var vacuum_dir = get_vacuum_dir(hitbox)
		x = fixed.mul(vacuum_dir.x, "-1")
		y = fixed.mul(vacuum_dir.y, "-1")

	var knockback_force = fixed.normalized_vec_times(x, y, hitbox.knockback)

	
	host.set_facing(Utils.int_sign(fixed.round(x)) * -1)
	var di = host.get_scaled_di(host.current_di)
	var di_force = fixed.vec_mul(di.x, di.y, fixed.mul(DI_STRENGTH, hitbox.di_modifier))

	if hitbox.hitbox_type == Hitbox.HitboxType.Burst:
		di_force.x = "0"
		di_force.y = "0"
	else:
		hitstun = di_shave_hitstun(hitstun, x, hitbox.dir_y)
		knockback_force = fixed.vec_mul(knockback_force.x, knockback_force.y, host.knockback_taken_modifier)

	var force_x = fixed.add(knockback_force.x, di_force.x)
	var force_y = fixed.add(knockback_force.y, di_force.y)
	host.apply_force(force_x, force_y)
	host.move_directly(0, -1)
	anim_name = "HurtAerial"

func _frame_0():
	pass

func _frame_1():
	if host.braced_attack:
		hitstun = brace_shave_hitstun(hitstun)

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
		if wall_slam:
			queue_state_change("WallSlam", bounce)
			return
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
		if host.is_grounded() and fixed.ge(vel.y, "0"):
			if hitbox.air_ground_bounce and !ground_bounced:
#				hitstun = hitstun + global_hitstun_modifier(hitbox.hitstun_ticks + hitstun_modifier(hitbox)) / 2
				begin_ground_bounce()
				host.set_vel(vel.x, fixed.mul(vel.y, "-1"))
			else:
				if current_tick > hitbox.minimum_grounded_frames:
					if knockdown or host.hp == 0:
						if hard_knockdown:
							return "HardKnockdown"
						else:
		#				host.start_invulnerability()
							return "Knockdown"
					else:
						if host.hp > 0:
							return "Landing"
						return "Knockdown"
				elif current_tick > 0:
					match hitbox.hit_height:
						Hitbox.HitHeight.High:
							anim_name = "HurtGroundedHigh"
						Hitbox.HitHeight.Mid:
							anim_name = "HurtGroundedMid"
						Hitbox.HitHeight.Low:
							anim_name = "HurtGroundedLow"
		else:
			anim_name = "HurtAerial"
				
	var extended_hitstun = hitbox.knockdown_extends_hitstun and hitbox.knockdown and !ground_bounced
	
	if !extended_hitstun and current_tick > hitstun:
		if can_act and host.hp > 0:
			return fallback_state
		else:
			enable_interrupt()
			can_act = true
