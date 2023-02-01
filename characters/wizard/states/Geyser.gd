extends WizardState

const MAX_DIST = "300"
const PARTICLE = preload("res://characters/wizard/GeyserParticleEffect.tscn")
const PROJECTILE = preload("res://characters/wizard/projectiles/GeyserProjectile.tscn")

var center_x = 0
var center_y = 0

var particle

func _tick():
	if started_in_air and (current_tick > 10 or current_tick < 6) and host.is_grounded():
		return "Landing"

func _exit():
	if particle:
		particle.queue_free()
		particle = null

func _frame_7():
	var dir = xy_to_dir(data["x"], data["y"])
	particle = spawn_particle_relative(PARTICLE, particle_position, Vector2(float(dir.x), float(dir.y)))
	var pos = host.get_pos()
	center_x = pos.x
	center_y = pos.y

func _frame_9():
	var dir = Vector2(data["x"], data["y"]).normalized()
	var pos = host.get_pos()
	var obj = host.spawn_object(PROJECTILE,0,0)
	var default = obj.state_machine.get_node("Default")
	var hitbox = default.get_node("Hitbox")
	for f in get_tree().get_nodes_in_group("Fighter"):
		if(f==host):
			continue
		if(f.is_ghost!=host.is_ghost):
			continue
		var fc = f.get_pos()
		var floc = dir*min(int(MAX_DIST),Vector2(pos.x-fc.x,pos.y-fc.y).length())
		var h = hitbox.duplicate()
		hitbox.copy_to(h)
		obj.hitboxes.append(h)
		default.add_child(h)
		h.init()
		h.host = obj
		h.x = int(floc.x*host.get_facing_int())
		h.y = int(floc.y-f.hurtbox.height)
	default.remove_child(hitbox)
	obj.hitboxes.remove(0)
	for i in obj.hitboxes.size():
		var h = obj.hitboxes[i]
		h.name = host.name+"_HB_"+str(i)
#		h.activate()
