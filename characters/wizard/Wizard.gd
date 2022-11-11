extends Fighter

const ORB_SCENE = preload("res://characters/wizard/projectiles/orb/Orb.tscn")
const ORB_PARTICLE_SCENE = preload("res://characters/wizard/projectiles/orb/OrbSpawnParticle.tscn")

const HOVER_AMOUNT = 400
const HOVER_MIN_AMOUNT = 50
const HOVER_VEL_Y_POS_MODIFIER = "0.70"
const HOVER_VEL_Y_NEG_MODIFIER = "0.97"
const ORB_SUPER_DRAIN = 2

var hover_left = 0
var hover_drain_amount = 5
var hover_gain_amount = 3
var hovering = false

var orb_projectile
var can_flame_wave = true
var can_vile_clutch = true

onready var liftoff_sprite = $Flip/LiftoffSprite

func init(pos=null):
	.init(pos)
	hover_left = HOVER_AMOUNT / 4
	if infinite_resources:
		hover_left = HOVER_AMOUNT
	
func apply_grav():
	if !hovering:
		.apply_grav()

func apply_grav_custom(grav: String, fall_speed: String):
	if !hovering:
		.apply_grav_custom(grav, fall_speed)

func spawn_orb():
		var orb = spawn_object(ORB_SCENE, -10, -56)
		spawn_particle_effect_relative(ORB_PARTICLE_SCENE, Vector2(-10, -56))
		orb_projectile = orb.obj_name

func tick():
	.tick()
	if hitlag_ticks <= 0:
		if is_grounded():
			hovering = false
		if hovering:
			if current_state().busy_interrupt_type == CharacterState.BusyInterrupt.Hurt:
				hovering = false
			else:
				var vel = get_vel()
				var modifier = HOVER_VEL_Y_POS_MODIFIER
				if fixed.lt(vel.y, "0"):
					modifier = HOVER_VEL_Y_NEG_MODIFIER
				set_vel(vel.x, fixed.mul(vel.y, modifier))
				if hover_left > 0:
					if !infinite_resources:
						hover_left -= hover_drain_amount
						if hover_left <= 0:
							hovering = false
							hover_left = 0
		else:
			hover_left += hover_gain_amount
			if hover_left > HOVER_AMOUNT:
				hover_left = HOVER_AMOUNT
	if orb_projectile:
		use_super_meter(ORB_SUPER_DRAIN)
		if super_meter == 0 and supers_available == 0:
			objs_map[orb_projectile].disable()

func process_extra(extra):
	.process_extra(extra)
	if extra.has("hover"):
		if can_hover():
			hovering = extra["hover"]
		else:
			hovering = false

func can_hover():
	return !is_grounded() and hover_left > HOVER_MIN_AMOUNT
