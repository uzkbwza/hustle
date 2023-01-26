extends BaseProjectile

export var frozen = false

const DAMAGE_FALLOFF_PER_PIXEL = "0.85"
const MIN_DISTANCE_START_SCALING = "256"
const HITSTUN_FALLOFF_PER_PIXEL = "1"

const MIN_HITSTUN_DIVISOR = "3"
const MIN_DAMAGE_DIVISOR = "2.5"

var distance = "0.0"

func init(pos=null):
	.init(pos)
	if frozen:
		if creator:
			creator.connect("got_hit", self, "disable")


func scale_damage(damage: int):
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
