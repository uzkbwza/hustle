extends CharacterState

const SPEED = "15"

export var push_back_amount = "-2.0"

var projectile_spawned = false

func _frame_0():
	projectile_spawned = false
	host.used_grappling_hook = true

func process_projectile(projectile):
	host.play_sound("GrapplingHook")
	projectile_spawned = true
	projectile.set_grounded(false)
	var force = xy_to_dir(data.x, data.y, SPEED)
	var vel = host.get_vel()
	projectile.apply_force(fixed.add(vel.x, force.x), fixed.add(vel.y, force.y))
	host.grappling_hook_projectile = projectile.obj_name
	projectile.start_y = host.get_pos().y

func _tick():
#	if host.combo_count > 0:
	host.apply_fric()
	host.apply_forces()
	if air_type == AirType.Aerial and projectile_spawned:
		if host.combo_count > 0:
			host.apply_grav()
		if host.is_grounded():
			return "Landing"

func is_usable():
	return host.grappling_hook_projectile == null and !host.used_grappling_hook and .is_usable()
