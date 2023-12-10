extends RobotState

const SPEED = "10.5"
#const HORIZ_MULTIPLIER = "1.5"

func _ready():
	pass # Replace with function body.

func _enter():
	host.sprite.flip_v = data.y > 0
	projectile_pos_y = -32 if data.y <= 0 else 16

func _exit():
	host.sprite.flip_v = false

func process_projectile(obj):
	var force = xy_to_dir(data.x, data.y, SPEED)
	obj.set_grounded(false)
	obj.apply_force(force.x, force.y)
	host.grenade_object = obj.obj_name

func is_usable():
	return .is_usable() and host.grenade_object == null
