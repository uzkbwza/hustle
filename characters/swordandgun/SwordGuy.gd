extends Fighter

signal bullet_used()

onready var shooting_arm = $"%ShootingArm"

const BARREL_LOCATION_X = "26"
const BARREL_LOCATION_Y = "-5"

var bullets_left = 6
var cut_projectile = null

func _ready():
	connect("got_hit", self, "on_got_hit")

func init():
	.init()
	bullets_left = 6

func get_barrel_location(angle):
	var barrel_location = fixed.rotate_vec(BARREL_LOCATION_X, BARREL_LOCATION_Y, angle)
	barrel_location.y = fixed.sub(barrel_location.y, "24")
	return barrel_location

func use_bullet():
	bullets_left -= 1
	emit_signal("bullet_used")

func on_got_hit():
	if cut_projectile:
		if objs_map.has(cut_projectile):
			objs_map[cut_projectile].disable()
			cut_projectile = null

