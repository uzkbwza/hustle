extends ObjectState

onready var center_hitbox = $CenterHitbox
onready var left_hitbox_1 = $LeftHitbox1
onready var left_hitbox_2 = $LeftHitbox2
onready var left_hitbox_3 = $LeftHitbox3
onready var left_hitbox_4 = $LeftHitbox4
onready var right_hitbox_1 = $RightHitbox1
onready var right_hitbox_2 = $RightHitbox2
onready var right_hitbox_3 = $RightHitbox3
onready var right_hitbox_4 = $RightHitbox4


var hitbox_start_angles = {}

var angle = "0"

func _ready():
	for hitbox in [
		left_hitbox_1,
		left_hitbox_2,
		left_hitbox_3,
		left_hitbox_4, 
		right_hitbox_1,
		right_hitbox_2,
		right_hitbox_3,
		right_hitbox_4,
	]:
		hitbox_start_angles[hitbox] = {x = hitbox.x, y = hitbox.y}

func _tick():
	if current_tick > 0:
		var dir = xy_to_dir(host.rotate_dir["x"], host.rotate_dir["y"])
		angle = fixed.lerp_string(angle, fixed.vec_to_angle(dir.x, dir.y), "0.2")
		host.sprite.rotation = float(angle)
		for hitbox in [
			left_hitbox_1,
			left_hitbox_2,
			left_hitbox_3,
			left_hitbox_4, 
			right_hitbox_1,
			right_hitbox_2,
			right_hitbox_3,
			right_hitbox_4,
		]:
			var vec = fixed.rotate_vec(str(hitbox_start_angles[hitbox].x), str(hitbox_start_angles[hitbox].y), angle)
			hitbox.x = fixed.round(vec.x)
			hitbox.y = fixed.round(vec.y)

func _frame_21():
#	host.screen_bump(Vector2(), 10, 0.25)
	pass

func _frame_38():
	host.disable()