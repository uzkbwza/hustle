extends RobotState

const SPEED = "7.0"

func _ready():
	pass # Replace with function body.

func process_projectile(obj):
	var force = xy_to_dir(data.x, data.y, SPEED)
	obj.apply_force(force.x, force.y)
	host.grenade_object = obj.obj_name

func is_usable():
	return .is_usable() and host.grenade_object == null
