extends DefaultFireball

onready var hitbox = $Hitbox

const BASE_DAMAGE = 10
const MIN_DAMAGE = 1
const BASE_HITSTUN = 30
const MIN_HITSTUN = 10
const LESS_DAMAGE_PER_PIXEL = "0.025"
const MIN_SPEED = "6"
const LESS_HITSTUN_PER_PIXEL = "0.05"
const SPEED_MULTIPLIER = "1.25"

var start_x = 0

func _enter():
	start_x = host.get_pos().x
#	print(start_x)

func _tick():
	if current_tick <= 1:
		move_x_string = fixed.mul(host.speed, SPEED_MULTIPLIER)
		if fixed.lt(move_x_string, MIN_SPEED):
			move_x_string = MIN_SPEED
		host.set_facing(host.facing)
	hitbox.damage = host.damage - fixed.round(fixed.mul(LESS_DAMAGE_PER_PIXEL, fixed.abs(str(host.get_pos().x - start_x))))
	hitbox.hitstun_ticks = BASE_HITSTUN - fixed.round(fixed.mul(LESS_HITSTUN_PER_PIXEL, fixed.abs(str(host.get_pos().x - start_x))))
#	print(hitbox.hitstun_ticks)
	if hitbox.hitstun_ticks < MIN_HITSTUN:
		hitbox.hitstun_ticks = MIN_HITSTUN
	if hitbox.damage < 0:
		host.disable()
	._tick()

func _frame_5():
	host.has_projectile_parry_window = true
