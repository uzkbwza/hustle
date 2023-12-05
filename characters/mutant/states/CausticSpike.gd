extends BeastState

const PUSH = "10.0"
const EXTRA_FORCE = "4.0"

func process_projectile(obj):
	var dir = xy_to_dir(data.x, data.y, EXTRA_FORCE)
	obj.apply_force(fixed.mul(PUSH, str(host.get_facing_int())), "0")
	obj.apply_force(dir.x, dir.y)
	obj.set_rotation(data)
	host.spike_projectile = obj.obj_name

func _enter():
	initiative_effect = (host.combo_count == 0 or started_in_air)

func _tick():
	if host.initiative and (host.combo_count == 0 or started_in_air):
		if current_tick == 1:
			current_tick = 7
		if current_tick == 20:
			enable_interrupt()
