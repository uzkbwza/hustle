extends Node2D

class_name BaseObj

signal object_spawned(object)
signal particle_effect_spawned(particle)

export var id = 1
export var dummy = false
export var _c_MovementAttributes = 0
export var gravity: String = "0.8"
export var ground_friction: String = "2.5"
export var air_friction: String = "0.2"
export var max_ground_speed: String = "15"
export var max_air_speed: String = "10"
export var max_fall_speed: String = "15"

onready var collision_box = $CollisionBox
onready var hurtbox = $Hurtbox
onready var particles = $"%Particles"
onready var state_machine = $StateMachine

onready var sprite = $"%Sprite"
onready var flip = $Flip

var debug_label

var chara = FGObject.new()

var stage_width = 0

var data
var obj_data
var current_tick = 0
var hitlag_ticks = 0
var combo_count = 0

var fixed_math = FixedMath.new()

var state_interruptable = false
var state_hit_cancellable = false

var invulnerable = false

func _ready():
	chara.id = id
	chara.set_gravity(gravity)
	chara.set_ground_friction(ground_friction)
	chara.set_air_friction(air_friction)
	chara.set_max_ground_speed(max_ground_speed)
	chara.set_max_air_speed(max_air_speed)
	chara.set_max_fall_speed(max_fall_speed)
	if id == 2:
		chara.set_facing(-1)
	state_machine.init()

func get_frames():
	return ReplayManager.frames[id]

func stop_particles():
	for particle in particles.get_children():
		particle.stop_emitting()

func update_data():
	data = get_data()
	obj_data = data["object_data"]
	data["state_data"] = {
		"state": state_machine.state.state_name,
		"frame": state_machine.state.current_tick,
	}

func get_facing():
	return chara.get_facing().keys()[0]

func spawn_object(projectile: PackedScene, pos_x: int, pos_y: int, relative=true):
	var obj = projectile.instance()
	add_child(obj)
	var pos = get_pos()
	obj.set_pos(pos.x + pos_x * (get_facing_int() if relative else 1), pos.y + pos_y)
	obj.set_facing(get_facing_int())
	obj.stage_width = stage_width
	obj.id = id
	remove_child(obj)
	emit_signal("object_spawned", obj)
	return obj

func start_invulnerability():
	invulnerable = true

func end_invulnerability():
	invulnerable = false

func spawn_particle_effect(particle_effect: PackedScene, pos: Vector2, dir= Vector2.RIGHT):
	if ReplayManager.resimulating:
		return
	var obj = particle_effect.instance()
	add_child(obj)
	obj.tick()
	var facing = -1 if dir.x < 0 else 1
	obj.position = pos
	if facing < 0:
		obj.rotation = (dir * Vector2(-1, -1)).angle()
	else:
		obj.rotation = dir.angle()
	obj.scale.x = facing
	remove_child(obj)

	emit_signal("particle_effect_spawned", obj)
	return obj
	
func update_collision_boxes():
	var pos = get_pos()
	collision_box.update_position(pos.x, pos.y)
	hurtbox.update_position(pos.x, pos.y)

func set_facing(facing: int):
	chara.set_facing(facing)
	flip.scale.x = -1 if facing < 0 else 1

func set_vel(x, y):
	check_params(x, y)
	chara.set_vel(str(x), str(y))

func get_vel():
	return {
		"x": data.object_data.vel_x,
		"y": data.object_data.vel_y,
	}

func get_facing_int():
	return -1 if get_facing() == "Left" else 1

func check_params(x, y):
	assert((x is int and y is int) or (x is String and y is String))

func set_x(x: int):
	chara.set_x(x)

func set_pos(x, y):
	check_params(x, y)
	if x is int:
		chara.set_position(x, y)
		return
	chara.set_position_str(x, y)

func get_data():
	return chara.get_data()

func get_active_hitboxes():
	var hitboxes = []
	for hitbox in state_machine.state.get_active_hitboxes():
		if hitbox.enabled:
			hitboxes.append(hitbox)
	hitboxes.sort_custom(self, "sort_hitboxes")
	return hitboxes
	
func sort_hitboxes(a, b):
	return a.priority < b.priority

func apply_force(x, y):
	check_params(x, y)
	if x is int:
		chara.apply_force(x, y)
		return
	chara.apply_force_str(x, y)

func apply_force_relative(x, y):
	check_params(x, y)
	if x is int:
		chara.apply_force_relative(x, y)
		return
	chara.apply_force_relative_str(x, y)

func apply_forces():
	chara.apply_forces()
	
func apply_forces_no_limit():
	chara.apply_forces_no_limit()

func apply_grav():
	chara.apply_grav()

func apply_fric():
	chara.apply_fric()

func apply_full_fric(fric):
	chara.apply_full_fric(fric)

func move_directly(x, y):
	check_params(x, y)
	if x is int:
		chara.move_directly(x, y)
		return
	chara.move_directly_str(x, y)

func move_directly_relative(x, y):
	check_params(x, y)
	if x is int:
		chara.move_directly_relative(x, y)
		return
	chara.move_directly_relative_str(x, y)

func _process(delta):
	if data:
		debug_info(data)

func debug_info(data):
	if debug_label:
		debug_label.text = ""
		debug_label.text = debug_dict("", data)

func debug_dict(text, dict):
	for key in dict:
		var data = dict[key]
		if data is Dictionary:
			text += debug_dict("", data)
		else:
			text += str(key) + ": " + str(data) + "\n"
	return text

func reset_momentum():
	chara.reset_momentum()

func is_grounded():
	return chara.is_grounded()

func set_grounded(on):
	chara.set_grounded(on)

func add_pushback(pushback):
	chara.add_pushback(pushback)
	
func update_grounded():
	chara.update_grounded()

func hit_by(hitbox: Hitbox):
	pass

func get_pos():
	return {
		"x": data.object_data.position_x,
		"y": data.object_data.position_y
	}
	
func xy_to_dir(x, y, mul="1.0", div="100.0"):
	var unscaled_force = fixed_math.vec_div(str(x), str(y), div)
	var force = fixed_math.vec_mul(unscaled_force["x"], unscaled_force["y"], mul)
	return FixedVec2String.new(force.x, force.y)
	
func on_state_started(state):
	state_interruptable = false
	state_hit_cancellable = false
	pass

func on_state_ended(state):
	pass

func get_collision_box():
	return { 
		"x1": data.object_data.position_x - collision_box.width + collision_box.x,
		"x2": data.object_data.position_x + collision_box.width + collision_box.x,
		"y1": data.object_data.position_y - collision_box.height + collision_box.y,
		"y2": data.object_data.position_y + collision_box.height + collision_box.y,
	}

func get_pos_visual():
	if !data:
		update_data()
	return Vector2(data.object_data.position_x, data.object_data.position_y)

func tick():
	if current_tick <= 0:
		update_data()

	if hitlag_ticks > 0:
		hitlag_ticks -= 1
	else:
		state_tick()
		update_data()
		current_tick += 1
		update_grounded()
	
	for particle in particles.get_children():
		particle.tick()
	update_collision_boxes()

func state_tick():
	state_machine.tick()
	if (!state_machine.state.endless) and state_machine.state.current_tick >= state_machine.state.anim_length and state_machine.queued_states == []:
		state_machine.queue_state(state_machine.state.fallback_state)
		state_machine.tick()

