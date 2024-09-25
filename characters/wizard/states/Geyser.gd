extends WizardState

const MAX_DISTS = [ 
	"300",
	"400",
	"500",
]

const STARTUP_LAG = 4

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

const DAMAGE = [
	130, 
	150, 
	170
]

const MINDAMAGE = [
	0,
	50,
	80,
]

const TIMING = [
	11,
	11,
	10,
]

const PLUS = [
	1,
	3,
	4,
]

const PRORATION = [
	6,
	5,
	4,
]

onready var hitbox1 = $Hitbox1
onready var hitbox2 = $Hitbox2
onready var hitbox3 = $Hitbox3

var center_x = 0
var center_y = 0

var particle
var hit = false

var charges = 3
var startup_lag = STARTUP_LAG

func _enter():
	charges = data["Charge"].count
	hit = false
	particle = null

func _frame_0():
	startup_lag = STARTUP_LAG
	var dir = xy_to_dir(data["Direction"]["x"], data["Direction"]["y"])
	var level = charges - 1
	var dist = MAX_DISTS[level]
	hitbox1.activated = false
	hitbox2.activated = false
	hitbox3.activated = false
	var hitbox = [hitbox1, hitbox2, hitbox3][level]
	hitbox.activated = true
	hitbox.damage = DAMAGE[level]
	hitbox.minimum_damage = MINDAMAGE[level]
	hitbox.start_tick = TIMING[level]
	hitbox.plus_frames = PLUS[level]
	hitbox.damage_proration = PRORATION[level]
	var to = fixed.vec_mul(dir.x, dir.y, dist)
	hitbox.to_x = fixed.round(to.x) * host.get_facing_int()
	hitbox.to_y = fixed.round(to.y)

func is_usable():
	return host.geyser_charge > 0 and .is_usable()

func _tick():
	if started_in_air and (current_tick > 10 or current_tick < 6) and host.is_grounded():
		return "Landing"
	if charges == 3 and current_tick == 1:
		current_tick = 2
	if startup_lag > 0:
		current_tick = 0
		startup_lag -= 1
	if particle:
		if !hit and current_tick < 14:
			var my_pos = host.get_pos()
			if is_instance_valid(particle):
				particle.position = Vector2(my_pos.x, my_pos.y) + particle_position


#func _exit():
#	if particle:
#		particle.queue_free()
#		particle = null

func _frame_7():
	var dir = xy_to_dir(data["Direction"]["x"], data["Direction"]["y"])
	particle = host._spawn_particle_effect(PARTICLES[charges - 1], particle_position, Vector2(float(dir.x), float(dir.y)))

#	host.start_geyser_particle(charges - 1, Vector2(float(dir.x), float(dir.y)).angle())
	var pos = host.get_pos()
	center_x = pos.x
	center_y = pos.y

func _frame_9():
	if !host.infinite_resources:
		host.geyser_charge -= charges
	if host.geyser_charge < 0:
		host.geyser_charge = 0


#func _frame_9():
#	if host.geyser_charge < 0:
#		host.geyser_charge = 0
#	var dir = xy_to_dir(data["Direction"]["x"], data["Direction"]["y"])
#	var pos = host.get_pos()
#	var obj = host.spawn_object(PROJECTILES[charges - 1],0,0)
#	var default = obj.state_machine.get_node("Default")
#	var hitbox = default.get_node("Hitbox")
#	var fc = host.opponent.get_pos()
#	var v1 = (MAX_DISTS[charges - 1])
#	var v2 = fixed.vec_len(str(pos.x-fc.x),str(pos.y-fc.y))
#	var v
#	if fixed.lt(v1, v2):
#		v = v1
#	else:
#		v = v2
#	var floc = fixed.vec_mul(dir.x, dir.y, v)
#	hitbox.x = fixed.round(fixed.mul(floc.x, str(host.get_facing_int())))
#	hitbox.y = fixed.round(fixed.sub(str(floc.y), str(host.hurtbox.height)))

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
func _on_hit_something(obj, _hitbox):
	if obj.is_in_group("Fighter"):
		hit = true
	._on_hit_something(obj, _hitbox)
