extends "res://characters/stickman/projectiles/fireball_states/Default.gd"
const STACKRIKEN_SCENE = preload("res://characters/stickman/projectiles/Stackriken.tscn")
const ROTATE_AMOUNT = 22.5

const STACK_FORCE_MULTIPLIER = "0.9"
const STACKRIKEN_REFRESH_FORCE_MULTIPLIER = "0.5"
const LIFETIME = 120

func _tick():
	._tick()
	host.sprite.rotation += deg2rad(ROTATE_AMOUNT) * host.get_facing_int()

	var fighter = host.get_fighter()
#	if fighter.combo_count <= 0:
	if current_tick > LIFETIME:
		host.apply_grav()
		host.set_vel("0", host.get_vel().y)
		host.apply_forces()

	if !host.can_stack:
		return
		
	var stackriken_out = host.get_fighter().stackriken_out

	for obj_name in host.objs_map:
		var obj = host.objs_map[obj_name]
		if obj and obj != host and !obj.disabled and obj.id == host.id and host.hurtbox.overlaps(obj.hurtbox): 
			if obj.is_in_group("NinjaShuriken"):
				if stackriken_out:
					continue
				if !obj.can_stack:
					continue
				var stackriken = host.spawn_object(STACKRIKEN_SCENE, 0, 0)
				var dir1 = fixed.vec_mul(fixed.mul(host.dir_x, str(host.get_facing_int())), host.dir_y, data.speed_modifier)
				var dir2 = fixed.vec_mul(fixed.mul(obj.dir_x, str(obj.get_facing_int())), obj.dir_y, obj.current_state().data.speed_modifier)
				var force = fixed.vec_add(dir1.x, dir1.y, dir2.x, dir2.y)
				force = fixed.vec_mul(force.x, force.y, STACK_FORCE_MULTIPLIER)
				stackriken.force_x = force.x
				stackriken.force_y = force.y
	#			stackriken.apply_force(force.x, force.y)
				obj.disable()
				host.disable()
			if obj.is_in_group("Stackriken"):
				host.disable()
				if obj.current_state() != null:
					obj.refresh()
					var dir1 = fixed.vec_mul(fixed.mul(host.dir_x, str(host.get_facing_int())), host.dir_y, data.speed_modifier)
					var force = fixed.vec_mul(dir1.x, dir1.y, STACKRIKEN_REFRESH_FORCE_MULTIPLIER)
					obj.apply_force(force.x, force.y)

func move():
	var dir = fixed.vec_mul(host.dir_x, host.dir_y, data.speed_modifier)
	host.move_directly_relative(dir.x, dir.y)
