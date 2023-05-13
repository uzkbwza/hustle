extends BeastState

const PUSH = "10.0"
const EXTRA_FORCE = "4.0"

func process_projectile(obj):
	var dir = xy_to_dir(data.x, data.y, EXTRA_FORCE)
	obj.apply_force(fixed.mul(PUSH, str(host.get_facing_int())), "0")
	obj.apply_force(dir.x, dir.y)
	obj.set_rotation(data)
