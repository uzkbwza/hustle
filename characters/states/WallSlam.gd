extends CharacterState

const GRAV = "0.25"
const MAX_FALL_SPEED = "5.0"

const MIN_DURATION = 20
const MIN_HEIGHT = -40

func _ready():
	is_hurt_state = true

func _enter():
	host.clipping_wall = true
	host.colliding_with_opponent = false
#	host.start_invulnerability()

func _frame_0():
	var dir = 1 if data == CharacterHurtState.BOUNCE.LEFT_WALL else -1
#	host.sprite.rotation = TAU/4 * -dir
	host.screen_bump(Vector2.RIGHT * dir, 20, 0.48)
	host.set_pos(host.stage_width * -dir, Utils.int_min(host.get_pos().y, MIN_HEIGHT)) 

func _exit():
	host.sprite.rotation = 0

func _tick():
	if current_tick > MIN_DURATION and host.is_grounded():
		return "Knockdown"
	host.apply_grav_custom(GRAV, MAX_FALL_SPEED)
	host.apply_forces()
