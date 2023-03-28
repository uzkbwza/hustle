extends WizardState

const MAX_DISTS = [ 
	"300",
	"400",
	"500",
]

const PARTICLES = [
	preload("res://characters/wizard/GeyserParticleEffect.tscn"),
	preload("res://characters/wizard/GeyserParticleEffect2.tscn"),
	preload("res://characters/wizard/GeyserParticleEffect3.tscn"),
]
const PROJECTILES = [
	preload("res://characters/wizard/projectiles/GeyserProjectile.tscn"),
	preload("res://characters/wizard/projectiles/GeyserProjectile2.tscn"),
	preload("res://characters/wizard/projectiles/GeyserProjectile3.tscn"),
]

var center_x = 0
var center_y = 0

var particle

var charges = 3

func _enter():
	charges = data["Charge"].count
	
func is_usable():
	return host.geyser_charge > 0 and .is_usable()

func _tick():
	if started_in_air and (current_tick > 10 or current_tick < 6) and host.is_grounded():
		return "Landing"
	if charges == 3 and current_tick == 1:
		current_tick = 2

func _exit():
	if particle:
		particle.queue_free()
		particle = null

func _frame_7():
	var dir = xy_to_dir(data["Direction"]["x"], data["Direction"]["y"])
	particle = spawn_particle_relative(PARTICLES[charges - 1], particle_position, Vector2(float(dir.x), float(dir.y)))
	var pos = host.get_pos()
	center_x = pos.x
	center_y = pos.y

func _frame_9():
	host.geyser_charge -= charges
	if host.geyser_charge < 0:
		host.geyser_charge = 0
	var dir = xy_to_dir(data["Direction"]["x"], data["Direction"]["y"])
	var pos = host.get_pos()
	var obj = host.spawn_object(PROJECTILES[charges - 1],0,0)
	var default = obj.state_machine.get_node("Default")
	var hitbox = default.get_node("Hitbox")
	for f in get_tree().get_nodes_in_group("Fighter"):
		if(f==host):
			continue
		if(f.is_ghost!=host.is_ghost):
			continue
		var fc = f.get_pos()
		var v1 = (MAX_DISTS[charges - 1])
		var v2 = fixed.vec_len(str(pos.x-fc.x),str(pos.y-fc.y))
		var v
		if fixed.lt(v1, v2):
			v = v1
		else:
			v = v2
		var floc = fixed.vec_mul(dir.x, dir.y, v)
		var h = hitbox.duplicate()
		hitbox.copy_to(h)
		obj.hitboxes.append(h)
		default.add_child(h)
		h.init()
		h.host = obj
		h.x = fixed.round(fixed.mul(floc.x, str(host.get_facing_int())))
		h.y = fixed.round(fixed.sub(str(floc.y), str(f.hurtbox.height)))

	default.remove_child(hitbox)
	obj.hitboxes.remove(0)
#	var dir = Vector2(data["Direction"]["x"], data["Direction"]["y"]).normalized()
#	var pos = host.get_pos()
#	var obj = host.spawn_object(PROJECTILES[charges - 1],0,0)
#	var default = obj.state_machine.get_node("Default")
#	var hitbox = default.get_node("Hitbox")
#	for f in get_tree().get_nodes_in_group("Fighter"):
#		if(f==host):
#			continue
#		if(f.is_ghost!=host.is_ghost):
#			continue
#		var fc = f.get_pos()
#		var floc = dir*min(int(MAX_DISTS[charges - 1]),Vector2(pos.x-fc.x,pos.y-fc.y).length())
#		var h = hitbox.duplicate()
#		hitbox.copy_to(h)
#		obj.hitboxes.append(h)
#		default.add_child(h)
#		h.init()
#		h.host = obj
#		h.x = int(floc.x*host.get_facing_int())
#		h.y = int(floc.y-f.hurtbox.height)
#	default.remove_child(hitbox)
#	obj.hitboxes.remove(0)

#	for i in obj.hitboxes.size():
#		var h = obj.hitboxes[i]
#		h.name = host.name+"_HB_"+str(i)
#		h.activate()
