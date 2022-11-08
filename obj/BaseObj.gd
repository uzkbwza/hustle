extends Node2D

class_name BaseObj

signal object_spawned(object)
signal particle_effect_spawned(particle)
signal initialized()
signal got_hit()

const RUMBLE_MODIFIER = 4.0
const MAX_RUMBLE = 10

export var id = 1
export var dummy = false
export var _c_MovementAttributes = 0
export var gravity: String = "0.8"
export var ground_friction: String = "2.5"
export var air_friction: String = "0.2"
export var max_ground_speed: String = "15"
export var max_air_speed: String = "10"
export var max_fall_speed: String = "15"
export(String, MULTILINE) var extra_state_variables

onready var collision_box = $CollisionBox
onready var hurtbox = $Hurtbox
onready var particles = $"%Particles"
onready var state_machine = $StateMachine

onready var sprite = $"%Sprite"
onready var flip = $Flip

var debug_label

var chara = FGObject.new()

var stage_width = 0

var obj_name: String

var data
var obj_data
var current_tick = 0
var hitlag_ticks = 0
var combo_count = 0

var is_ghost = false

var spawn_data = null
var disabled = false

var creator_name = null
var creator = null

var fixed = FixedMath.new()

var state_interruptable = true
var state_hit_cancellable = false

var invulnerable = false

var projectile_invulnerable = false

var state_variables = ["id", "projectile_invulnerable", "creator_name", "name", "obj_name", "stage_width", "hitlag_ticks", "combo_count", "invulnerable", "current_tick", "disabled", "state_interruptable", "state_hit_cancellable"]

var hitboxes = []

var initialized = false
var rng = BetterRng.new()

var objs_map = {
	
}

var sounds = {
	
}

func _enter_tree():
	if obj_name:
		name = obj_name

func _ready():
	state_machine.connect("state_exited", self, "_on_state_exited")
	state_variables.append_array(Utils.split_lines(extra_state_variables))
	if creator_name:
		creator = objs_map[creator_name]
	if !obj_name:
		obj_name = name

	for sound in $Sounds.get_children():
		sounds[sound.name] = sound
		sound.bus = "Fx"

func play_sound(sound_name):
	if is_ghost or ReplayManager.resimulating:
		return
	if sound_name in sounds:
		sounds[sound_name].play()

func setup_hitbox_names():
	for i in range(hitboxes.size()):
		if obj_name != "":
			hitboxes[i].name = (obj_name) + "_" + "HB" + "_" + str(i)
		else:
			hitboxes[i].name = (name) + "_" + "HB" + "_" + str(i)

func _on_state_exited(state: ObjectState):
	for hitbox in hitboxes:
		hitbox.deactivate()

func current_state():
	return state_machine.state

func init(pos=null):
	chara.id = id
	chara.set_gravity(gravity)
	chara.set_ground_friction(ground_friction)
	chara.set_air_friction(air_friction)
	chara.set_max_ground_speed(max_ground_speed)
	chara.set_max_air_speed(max_air_speed)
	chara.set_max_fall_speed(max_fall_speed)

	state_machine.init("", spawn_data)
	setup_hitbox_names()
	update_data()
	initialized = true
	emit_signal("initialized")

func rumble(amount: float, ticks: int):
	var time = ticks / 60.0
	var tween = create_tween()
#	tween.set_ease(Tween.EASE_OUT)
#	tween.set_trans(Tween.TRANS_CIRC)
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_method(self, "set_rumble", amount, 0.0, time)

func set_rumble(amount):
	flip.position = rng.random_vec() * min((amount * RUMBLE_MODIFIER), MAX_RUMBLE)
	if amount < 0.05:
		flip.position = Vector2()
	pass

func change_state(state_name, state_data=null):
	state_machine._change_state(state_name, state_data)
	
func copy_to(o: BaseObj):
	var current_state = current_state()
	o.state_machine.starting_state = current_state.name
	o.spawn_data = current_state.copy_data()
	o.set_pos(get_pos().x, get_pos().y)
	if creator_name and o.objs_map.has(creator_name):
		o.creator = o.objs_map[creator_name]
	o.init()
	o.update_data()

	for variable in state_variables:
		var v = get(variable)
		if v is Array or v is Dictionary:
			o.set(variable, v.duplicate(true))
		else:
			o.set(variable, get(variable))
#	o.chara.set_facing(get_facing_int())
	o.change_state(current_state.state_name, current_state.data)
	
	for state in o.state_machine.states_map:
		state_machine.states_map[state].copy_to(o.state_machine.states_map[state])
#	while o.current_state().current_tick < current_state.current_tick:
#		o.normal_tick()
#		o.set_pos(get_pos().x, get_pos().y)
#		if o.current_state().state_name != current_state.state_name:
#			break
	o.current_state().current_tick = current_state.current_tick
	o.set_pos(get_pos().x, get_pos().y)

#	o.set_vel(get_vel().x, get_vel().y)
#	o.current_state().current_tick = current_state.current_tick
#	o.stage_width = stage_width
#	o.hitlag_ticks = hitlag_ticks
#	o.combo_count = combo_count
#	o.invulnerable = invulnerable
#	o.current_tick = current_tick
#	if o.has_method("clean_parried_hitboxes"):
#		o.clean_parried_hitboxes()
	o.chara.update_grounded()
#	o.set_pos(get_pos().x, get_pos().y)
#	o.set_facing(get_facing_int())
	o.update_data()
	o.sprite.rotation = sprite.rotation
	o.chara.set_facing(get_facing_int())
	var pos = get_pos()
	for i in range(hitboxes.size()):
		o.hitboxes[i].hit_objects = hitboxes[i].hit_objects.duplicate()
		if hitboxes[i].active:
			o.hitboxes[i].activate()
			o.hitboxes[i].tick = hitboxes[i].tick
			o.hitboxes[i].enabled = hitboxes[i].enabled
			hitboxes[i].copy_to(o.hitboxes[i])
			o.hitboxes[i].update_position(pos.x, pos.y)
	chara.copy_to(o.chara)

func get_frames():
	return ReplayManager.frames[id]

func stop_particles():
	for particle in particles.get_children():
		particle.stop_emitting()
	pass

func update_data():
	data = get_data()
	obj_data = data["object_data"]
	data["state_data"] = {
		"state": state_machine.state.state_name,
		"frame": state_machine.state.current_tick,
	}
	update_collision_boxes()

func obj_local_pos(obj: BaseObj):
	update_data()
	var pos = get_pos()
	obj.update_data()
	var o_pos = obj.get_pos()
	return {
		"x": o_pos.x - pos.x,
		"y": o_pos.y - pos.y,
	}

func obj_local_center(obj: BaseObj):
	update_data()
	var pos = get_hurtbox_center()
	obj.update_data()
	var o_pos = obj.get_hurtbox_center()
	return {
		"x": o_pos.x - pos.x,
		"y": o_pos.y - pos.y,
	}

func get_global_center():
	var pos = get_pos()
	var center = get_hurtbox_center()
	return 

func get_facing():
	return chara.get_facing().keys()[0]

func spawn_object(projectile: PackedScene, pos_x: int, pos_y: int, relative=true, data=null, local=true):
	var obj = projectile.instance()
	obj.creator_name = obj_name
#	obj.obj_name = str(objs_map.size() + 1)r
	obj.objs_map = objs_map
	obj.is_ghost = is_ghost
	obj.obj_name = str(objs_map.size() + 1)
	obj.spawn_data = data
#	add_child(obj)
	var pos = get_pos()
	if local:
		obj.set_pos(pos.x + pos_x * (get_facing_int() if relative else 1), pos.y + pos_y)
	else:
		obj.set_pos(pos_x, pos_y)
	obj.set_facing(get_facing_int())
	obj.stage_width = stage_width
	obj.id = id
	
#	remove_child(obj)
	obj.obj_name = str(objs_map.size() + 1)
	emit_signal("object_spawned", obj)
	return obj

func get_hurtbox_center():
	return hurtbox.get_center()

func start_projectile_invulnerability():
	projectile_invulnerable = true

func end_projectile_invulnerability():
	projectile_invulnerable = false

func start_invulnerability():
	invulnerable = true

func end_invulnerability():
	invulnerable = false

func spawn_particle_effect(particle_effect: PackedScene, pos: Vector2, dir= Vector2.RIGHT):
	if ReplayManager.resimulating:
		return
	if !initialized:
		yield(self, "initialized")
	call_deferred("_spawn_particle_effect", particle_effect, pos, dir)
	
func spawn_particle_effect_relative(particle_effect: PackedScene, pos: Vector2 = Vector2(), dir= Vector2.RIGHT):
	if ReplayManager.resimulating:
		return
	if !initialized:
		yield(self, "initialized")
	var p = get_pos_visual()
	pos.x *= get_facing_int()
	call_deferred("_spawn_particle_effect", particle_effect, pos + p, dir)


func _spawn_particle_effect(particle_effect: PackedScene, pos: Vector2, dir= Vector2.RIGHT):
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

func get_camera():
	return get_tree().get_nodes_in_group("Camera")[0] if !is_ghost else null

func update_collision_boxes():
	var pos = get_pos()
	collision_box.update_position(pos.x, pos.y)
	hurtbox.update_position(pos.x, pos.y)

func set_facing(facing: int):
	if facing != 1 and facing != -1:
		facing = 1
	chara.set_facing(facing)
	if is_instance_valid(flip):
		flip.scale.x = -1 if facing < 0 else 1
	if initialized:
		update_data()

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
		if hurtbox:
			hurtbox.update_position(x, y)
		if collision_box:
			collision_box.update_position(x, y)
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

func apply_grav_custom(grav: String, fall_speed: String):
	chara.apply_grav_custom(grav, fall_speed)

func apply_grav():
	chara.apply_grav()

func apply_fric():
	chara.apply_fric()

func apply_full_fric(fric):
	chara.apply_full_fric(fric)
	
func apply_y_fric(fric):
	chara.apply_y_fric(fric)

func get_object_dir(obj):
	var dir = Utils.int_sign(obj.get_pos().x - get_pos().x)
	if dir == 0:
		return get_facing_int()
	return dir

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
	emit_signal("got_hit")

func get_pos():
	return {
		"x": data.object_data.position_x,
		"y": data.object_data.position_y
	}
	
func xy_to_dir(x, y, mul="1.0", div="100.0"):
	var unscaled_force = fixed.vec_div(str(x), str(y), div)
	var force = fixed.vec_mul(unscaled_force["x"], unscaled_force["y"], mul)
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
		normal_tick()
	
#	for particle in particles.get_children():
#		particle.tick()
	update_collision_boxes()

func state_tick():
	state_machine.tick()
	if (!state_machine.state.endless) and state_machine.state.current_tick >= state_machine.state.anim_length and state_machine.queued_states == []:
		state_machine.queue_state(state_machine.state.fallback_state)
		state_machine.tick()

func normal_tick():
	state_tick()
	update_data()
	current_tick += 1
	update_grounded()

func _draw():
	pass
