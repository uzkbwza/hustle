extends CharacterState

const GRAV = "0.25"
const MAX_FALL_SPEED = "5.0"
const GRAV_PER_SLAM = "0.2"
const FALL_SPEED_PER_SLAM = "0.5"

const MIN_DURATION = 20
const MIN_HEIGHT = -30

const DI_EFFECT = "10"
var dir

func _ready():
	is_hurt_state = true

func _enter():
	host.clipping_wall = true
	host.colliding_with_opponent = false
#	host.start_invulnerability()

func _frame_0():
	dir = 1 if data == CharacterHurtState.BOUNCE.LEFT_WALL else -1
#	host.sprite.rotation = TAU/4 * -dir
	host.screen_bump(Vector2.RIGHT * dir, 15, 0.28)
	var di = fixed.mul(host.get_scaled_di(host.current_di).y, DI_EFFECT)
	var y_pos = Utils.int_min(host.get_pos().y, MIN_HEIGHT) + fixed.round(di)
	
	if host.wall_slams == 0:
		host.combo_proration += 1
		pass
	host.wall_slams += 1

	host.set_pos(host.stage_width * -dir, y_pos) 

func _exit():
	host.sprite.rotation = 0

func _tick():
	if current_tick > (MIN_DURATION - (host.wall_slams - 1) * 8) + (5 if !host.is_grounded() else 0):
		if host.is_grounded():
			return "Knockdown"
		else:
			enable_interrupt()
			queue_state_change("Fall")
#	dir = 1 if data == CharacterHurtState.BOUNCE.LEFT_WALL else -1
	if dir != null:
		host.set_x(host.stage_width * -dir)
		host.set_facing(dir)
	var grav = fixed.add(GRAV, fixed.mul(GRAV_PER_SLAM, str(host.wall_slams - 1)))
	var fall_speed = fixed.add(MAX_FALL_SPEED, fixed.mul(FALL_SPEED_PER_SLAM, str(host.wall_slams - 1)))
	host.apply_grav_custom(grav, fall_speed)
	host.apply_forces()
	if current_tick > 30:
		enable_interrupt()
		return "Fall"
