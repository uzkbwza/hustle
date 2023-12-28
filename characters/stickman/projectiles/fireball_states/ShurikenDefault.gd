extends "res://characters/stickman/projectiles/fireball_states/Default.gd"
const STACKRIKEN_SCENE = preload("res://characters/stickman/projectiles/Stackriken.tscn")
const ROTATE_AMOUNT = 22.5

const STACK_FORCE_MULTIPLIER = "0.9"

func _tick():
	._tick()
	host.sprite.rotation += deg2rad(ROTATE_AMOUNT) * host.get_facing_int()
	if host.get_fighter().stackriken_out:
		return

	for obj_name in host.objs_map:
		var obj = host.objs_map[obj_name]
		if obj and obj != host and !obj.disabled and obj.id == host.id and obj.is_in_group("NinjaShuriken") and host.hurtbox.overlaps(obj.hurtbox):
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


func move():

		var dir = fixed.vec_mul(host.dir_x, host.dir_y, data.speed_modifier)
		host.move_directly_relative(dir.x, dir.y)
