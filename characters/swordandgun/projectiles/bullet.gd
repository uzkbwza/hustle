extends BaseProjectile

export var frozen = false

const DAMAGE_FALLOFF_PER_PIXEL = "0.85"
const MIN_DISTANCE_START_SCALING = "256"
const HITSTUN_FALLOFF_PER_PIXEL = "1"

const MIN_HITSTUN_DIVISOR = "3"
const MIN_DAMAGE_DIVISOR = "2.5"

const SHOOT_TIMER = 10

var distance = "0.0"
var shoot_frame = 0
var shoot_timer = 0
var shot = false

var last_hit_by = ""
var got_hit = false
var dir_x = "0.0"
var dir_y = "0.0"

func init(pos=null):
	.init(pos)
#	if frozen:
#		if creator:
#			creator.connect("got_hit", self, "disable")

func tick():
	.tick()
	if shoot_timer > 0:
		shoot_timer -= 1
		if shoot_timer == 0:
			current_state().f1()
			shoot_frame = 2
	if shoot_frame > 0:
		shoot_frame -= 1
		if shoot_frame == 1:
			current_state().f2()
		if shoot_frame == 0:
			current_state().f3()

func scale_damage(damage: int):
	if frozen:
		return damage
	if fixed.lt(distance, MIN_DISTANCE_START_SCALING):
		return damage
	var falloff = fixed.mul(DAMAGE_FALLOFF_PER_PIXEL, fixed.sub(distance, MIN_DISTANCE_START_SCALING))
	var min_damage = fixed.div(str(damage), MIN_DAMAGE_DIVISOR)
	var scaled_damage = fixed.sub(str(damage), falloff)
	if fixed.lt(scaled_damage, min_damage):
		return fixed.round(min_damage)
	return fixed.round(scaled_damage)
#	return fixed.round()

func scale_hitstun(hitstun: int):
	if fixed.lt(distance, MIN_DISTANCE_START_SCALING):
		return hitstun
	var falloff = fixed.mul(HITSTUN_FALLOFF_PER_PIXEL, fixed.sub(distance, MIN_DISTANCE_START_SCALING))
	var min_hitstun = fixed.div(str(hitstun), MIN_HITSTUN_DIVISOR)
	var scaled_hitstun = fixed.sub(str(hitstun), falloff)
	if fixed.lt(scaled_hitstun, min_hitstun):
		return fixed.round(min_hitstun)
	return fixed.round(scaled_hitstun)

func hit_by(hitbox):
	.hit_by(hitbox)
	if got_hit:
		return
	got_hit = true
	shoot_frame = 2
	shot = true
	current_state().f1()
	var hitter = obj_from_name(hitbox.host)
	if hitter:
		if hitter.is_in_group("Fighter"):
			last_hit_by = hitbox.host
	var dir = fixed.normalized_vec(hitbox.dir_x, hitbox.dir_y)
	dir_x = fixed.mul(dir.x, get_hitbox_x_dir(hitbox))
	dir_y = dir.y

func shoot():
	if shot:
		return
	shoot_timer = SHOOT_TIMER

func get_owned_fighter():
	if last_hit_by == "":
		return get_fighter()
	var obj = obj_from_name(last_hit_by)
	if obj:
		return obj.get_fighter()
