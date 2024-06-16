extends BeastState

const PUSH = "10.0"
const EXTRA_FORCE = "9.0"

var combo_lag = 0

func process_projectile(obj):
	obj.set_grounded(false)
	var dir = xy_to_dir(data.x, data.y, EXTRA_FORCE)
	obj.apply_force(fixed.mul(PUSH, str(host.get_facing_int())), "0")
	obj.apply_force(dir.x, dir.y)
	obj.set_rotation(data)
	host.spike_projectile = obj.obj_name

func _enter():
	if host.combo_count > 0 and host.is_grounded():
		combo_lag = 4
	pass

func _tick():
	if combo_lag > 0:
		current_tick = 1
		combo_lag -= 1
	if (host.combo_count > 0 and started_in_air):
		if current_tick == 1:
			current_tick = 5
		if current_tick == 18:
			enable_interrupt()
