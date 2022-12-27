extends Fighter

signal bullet_used()

onready var shooting_arm = $"%ShootingArm"

const BARREL_LOCATION_X = "26"
const BARREL_LOCATION_Y = "-5"
const GUN_PICKUP_DISTANCE = "26"
const IS_COWBOY = true # lol

var bullets_left = 6
var cut_projectile = null
var lasso_projectile = null
var used_aerial_h_slash = false
var has_gun = true
var gun_projectile = null


func _ready():
	shooting_arm.set_material(sprite.get_material())

func init(pos=null):
	.init(pos)
	bullets_left = 6

func get_barrel_location(angle):
	var barrel_location = fixed.rotate_vec(BARREL_LOCATION_X, BARREL_LOCATION_Y, angle)
	barrel_location.y = fixed.sub(barrel_location.y, "24")
	return barrel_location

func tick():
	.tick()
	if objs_map.has(cut_projectile):
		var proj = objs_map[cut_projectile]
		if proj == null or proj.disabled:
			cut_projectile = null
	if is_grounded() and used_aerial_h_slash:
		used_aerial_h_slash = false
	if !has_gun and gun_projectile != null:
		var gun = objs_map[gun_projectile]
		if is_instance_valid(gun) and gun.data and !gun.disabled:
			var dist = obj_local_center(gun)
			if gun.can_be_picked_up and fixed.lt(fixed.vec_len(str(dist.x), str(dist.y)), GUN_PICKUP_DISTANCE):
				gun.disable()
				has_gun = true
				gun_projectile = null
				play_sound("GunPickup")

func use_bullet():
	if infinite_resources:
		return
	bullets_left -= 1
	emit_signal("bullet_used")

func on_got_hit():
	if cut_projectile:
		if objs_map.has(cut_projectile):
			objs_map[cut_projectile].disable()
			cut_projectile = null

func _draw():
	._draw()
	if lasso_projectile:
		var obj = objs_map[lasso_projectile]
		var obj_pos = obj.get_pos()
		var draw_target = to_local(Vector2(obj_pos.x, obj_pos.y))
		draw_target -= draw_target.normalized() * 8
		draw_line(Vector2(0, -16), draw_target, Color("704137"), 2.0, false)

