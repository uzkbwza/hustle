extends Node2D

class_name BaseObj

signal object_spawned(object)
signal particle_effect_spawned(particle)
signal initialized()
signal got_hit()
signal got_hit_by_fighter()
signal got_hit_by_projectile()
signal hitbox_refreshed(hitbox)
signal global_hitlag(amount)

const RUMBLE_MODIFIER = 4.0
const MAX_RUMBLE = 10
const MIN_VELOCITY = "0.0001"

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

export var damages_own_team = false

export var has_projectile_parry_window = true
export var always_parriable = false

export var throw_positions: Dictionary = {}

onready var collision_box = $CollisionBox
onready var hurtbox = $Hurtbox
onready var particles = $"%Particles"
onready var state_machine = $StateMachine

onready var sprite = $"%Sprite"
onready var flip = $Flip

var debug_label

var chara = FGObject.new()

var stage_width = 0
var ceiling_height = 0
var has_ceiling = false

var obj_name: String

var custom_hitspark

var data
var obj_data
var current_tick = 0
var game_tick = 0
var hitlag_ticks = 0
var combo_count = 0

var gravity_enabled = true
var last_hit_frame = 0

var is_ghost = false

var spawn_data = null
var disabled = false

var creator_name = null
var creator = null
var can_update_sprite = true

var fixed = FixedMath.new()
var native = NativeMethods.new()

var state_interruptable = true
var state_hit_cancellable = false

var invulnerable = false
var grounded_attack_immune = false
var aerial_attack_immune = false

var use_platforms = false
var last_object_hit = ""

var default_hurtbox = {
	"x": 0,
	"y": 0,
	"width": 0,
	"height": 0,
}

var projectile_invulnerable = false
var throw_invulnerable = false

var state_variables = ["id", "grounded_attack_immune", "game_tick", "match_seed", "aerial_attack_immune", "last_object_hit", "can_update_sprite", "last_hit_frame", "damages_own_team", "ceiling_height", "has_ceiling", "has_projectile_parry_window", "always_parriable", "use_platforms", "gravity", "ground_friction", "air_friction", "max_ground_speed", "max_air_speed", "max_fall_speed", "projectile_invulnerable", "gravity_enabled", "default_hurtbox", "throw_invulnerable", "creator_name", "name", "obj_name", "stage_width", "hitlag_ticks", "combo_count", "invulnerable", "current_tick", "disabled", "state_interruptable", "state_hit_cancellable"]

var hitboxes = []

var previous_state = ""

var fighter_owner

var initialized = false
var rng = BetterRng.new()

var objs_map = {
	
}

var sounds = {
	
}

var logic_rng: BetterRng
var logic_rng_static: BetterRng
var logic_rng_seed = 0
var logic_rng_static_seed = 0

func _enter_tree():
	if obj_name:
		name = obj_name
	add_to_group("BaseObj")

func get_p1():
	return obj_from_name("P1")

func get_p2():
	return obj_from_name("P2")

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

func global_hitlag(amount, force=false):
#	if is_ghost:
#		return
#	if !ReplayManager.playback:
#		return
	if !force and !Global.replay_extra_freeze_frames:
		return
	if amount > 0 and amount < 1:
		amount == 1
	emit_signal("global_hitlag", round(amount))

func play_sound(sound_name):
	if is_ghost or ReplayManager.resimulating:
		return
	if sound_name in sounds:
		sounds[sound_name].play()

func stop_sound(sound_name):
	if is_ghost or ReplayManager.resimulating:
		return
	if sound_name in sounds:
		sounds[sound_name].stop()

func refresh_hitboxes():
	for hitbox in hitboxes:
		hitbox.hit_objects = []
		emit_signal("hitbox_refreshed", hitbox.name)

func setup_hitbox_names():
	for i in range(hitboxes.size()):
		if obj_name != "":
			hitboxes[i].name = (obj_name) + "_" + "HB" + "_" + str(i)
		else:
			hitboxes[i].name = (name) + "_" + "HB" + "_" + str(i)

func _on_state_exited(state):
	for hitbox in hitboxes:
		hitbox.deactivate()

func on_got_push_blocked():
	pass

func get_owner():
	if creator:
		return creator.get_owner()
	return self

func current_state():
	return state_machine.state

func is_otg():
	if current_state() == null:
		return false
	return current_state().state_name == "Knockdown" or current_state().state_name == "HardKnockdown"

func init(pos=null):
	if initialized:
		return
	chara.id = id
	chara.set_gravity(gravity)
	chara.set_ground_friction(ground_friction)
	chara.set_air_friction(air_friction)
	chara.set_max_ground_speed(max_ground_speed)
	chara.set_max_air_speed(max_air_speed)
	chara.set_max_fall_speed(max_fall_speed)
	default_hurtbox.x = hurtbox.x
	default_hurtbox.y = hurtbox.y
	default_hurtbox.width = hurtbox.width
	default_hurtbox.height = hurtbox.height
	state_machine.init("", spawn_data)
	setup_hitbox_names()
	update_data()
	initialized = true
	emit_signal("initialized")
	if creator and creator.custom_hitspark:
		for hitbox in hitboxes:
			hitbox.HIT_PARTICLE = creator.custom_hitspark

func reset_hurtbox():
	hurtbox.x = default_hurtbox.x
	hurtbox.y = default_hurtbox.y
	hurtbox.width = default_hurtbox.width
	hurtbox.height = default_hurtbox.height

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

func change_state(state_name, state_data=null, enter=true, exit=true):
	state_machine._change_state(state_name, state_data, enter, exit)

func obj_from_name(name):
	if name is String and name in objs_map:
		var obj = objs_map[name]
		if obj != null:
			if !obj.disabled:
				return obj

func _on_hit_something(obj, hitbox):
	if last_hit_frame == current_tick:
		if hit_fighter_last():
			return
	last_object_hit = obj.obj_name
	last_hit_frame = current_tick

func hit_fighter_last():
	return last_object_hit == get_opponent().obj_name or last_object_hit == get_fighter().obj_name

func can_be_thrown():
	return !throw_invulnerable

func copy_to(o: BaseObj):
	if !initialized:
		init()
	var current_state = current_state()
#	print(current_state().property_list)
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
#
	for state in o.state_machine.states_map:
		state_machine.states_map[state].copy_to(o.state_machine.states_map[state])
#	state_machine.states_map[current_state().state_name].copy_to(o.state_machine.states_map[current_state().state_name])

	for state in state_machine.states_stack:
		o.state_machine.states_stack.append(o.state_machine.states_map[state.name])

	

	o.current_state().current_tick = current_state.current_tick

#	o.set_vel(get_vel().x, get_vel().y)
#	o.current_state().current_tick = current_state.current_tick
	o.stage_width = stage_width
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
	o.set_facing(get_facing_int())
	var pos = get_pos()
	for i in range(hitboxes.size()):
		o.hitboxes[i].hit_objects = hitboxes[i].hit_objects.duplicate()
		if hitboxes[i].active:
			o.hitboxes[i].activate()
			o.hitboxes[i].tick = hitboxes[i].tick
			o.hitboxes[i].enabled = hitboxes[i].enabled
			hitboxes[i].copy_to(o.hitboxes[i])
			o.hitboxes[i].update_position(pos.x, pos.y)
	hurtbox.copy_to(o.hurtbox)
	o.projectile_invulnerable = projectile_invulnerable
	o.invulnerable = invulnerable

	chara.copy_to(o.chara)
	o.set_facing(get_facing_int())
#	var vel = get_vel()
#	o.set_vel(vel.x, vel.y)
#	o.update_data()
	for state in state_machine.queued_states:
		o.state_machine.queued_states.append(state)
	for datum in state_machine.queued_data:
		o.state_machine.queued_data.append(datum)

	for state in o.state_machine.states_map:
		state_machine.states_map[state].copy_hurtbox_states(o.state_machine.states_map[state])
	o.logic_rng = BetterRng.new()
	o.logic_rng_static = BetterRng.new()
	
	o.logic_rng.seed = logic_rng_seed
	o.logic_rng_static.seed = logic_rng_static_seed
	
	o.logic_rng.state = logic_rng.state
	o.logic_rng_static.state = logic_rng_static.state

	
func get_frames():
	return ReplayManager.frames[id]

func stop_particles():
	for particle in particles.get_children():
		particle.stop_emitting()
	pass

func get_hitbox_x_dir(hitbox):
	var x = fixed.mul(hitbox.dir_x, "-1" if hitbox.facing == "Left" else "1")
	if hitbox.reversible:
		var dir = Utils.int_sign(hitbox.pos_x - get_pos().x)
		var modifier = "1"
		if dir == -1 and hitbox.facing == "Left":
			modifier = "-1"
		if dir == 1 and hitbox.facing == "Right":
			modifier = "-1"
		x = fixed.mul(x, modifier)
	return x

func get_current_sprite_frame() -> Texture:
	return sprite.frames.get_frame(sprite.animation, sprite.frame)

func get_current_sprite_frame_path() -> String:
	return get_current_sprite_frame().resource_path

func get_current_sprite_frame_number():
	return Utils.number_from_string(get_current_sprite_frame_path().get_file().split(".")[0])

func turn_around():
	set_facing(get_facing_int() * -1)

func update_data():
	data = get_data()
	obj_data = data["object_data"]
	if initialized:
		data["state_data"] =  {
			"state": state_machine.state.state_name,
			"frame": state_machine.state.current_tick,
		}
	else:
		data["state_data"] = {
			"state": "",
			"frame": 0,
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

func get_opponent():
	return null

func get_fighter():
	return null

func hash_static_rng():
	var input_hash = hash(game_tick)
	logic_rng_static.seed = hash(logic_rng_static.state + input_hash)
	
func hash_rng():
	var fighter = get_fighter()
	var opponent = get_opponent()
	var input_hash = hash(fighter.get_state_hash()) + hash(opponent.get_state_hash())
	logic_rng.seed = hash(logic_rng.state + input_hash)
#	print(logic_rng.seed)

func obj_distance(obj):
	var my_pos = get_pos()
	var obj_pos = obj.get_pos()
	return fixed.vec_dist(str(my_pos.x), str(my_pos.y), str(obj_pos.x), str(obj_pos.y))

func spawn_object(projectile: PackedScene, pos_x: int, pos_y: int, relative=true, data=null, local=true):
	var obj = projectile.instance()
	obj.creator_name = obj_name
#	obj.obj_name = str(objs_map.size() + 1)r
	obj.objs_map = objs_map
	obj.is_ghost = is_ghost
	obj.obj_name = str(objs_map.size() + 1)
	obj.spawn_data = data
	obj.stage_width = stage_width
#	add_child(obj)
	var pos = get_pos()
	if local:
		obj.set_pos(pos.x + pos_x * (get_facing_int() if relative else 1), pos.y + pos_y)
	else:
		obj.set_pos(pos_x, pos_y)
	obj.set_facing(get_facing_int())
	obj.id = id
	
#	remove_child(obj)
	obj.obj_name = str(objs_map.size() + 1)
	emit_signal("object_spawned", obj)
	return obj

func get_hurtbox_center():
	return hurtbox.get_center()

func get_hurtbox_center_float():
	return hurtbox.get_center_float()

func hurtbox_pos_relative():
	return { 
		"x": hurtbox.x * get_facing_int(),
		"y": hurtbox.y,
	}

func hurtbox_pos_float():
	return Vector2(hurtbox.x, hurtbox.y)

func hurtbox_pos_relative_float():
	return Vector2(hurtbox.x * get_facing_int(), hurtbox.y)

func start_throw_invulnerability():
	throw_invulnerable = true

func end_throw_invulnerability():
	throw_invulnerable = false

func start_projectile_invulnerability():
	projectile_invulnerable = true

func end_projectile_invulnerability():
	projectile_invulnerable = false

func start_aerial_attack_invulnerability():
	aerial_attack_immune = true

func end_aerial_attack_invulnerability():
	aerial_attack_immune = false

func start_grounded_attack_invulnerability():
	grounded_attack_immune = true

func end_grounded_attack_invulnerability():
	grounded_attack_immune = false

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
	var cameras = get_tree().get_nodes_in_group("Camera")
	return cameras[0] if cameras.size() > 0 and !is_ghost else null

func grab_camera_focus():
	var camera = get_camera()
	if camera:
		camera.focused_object = self

func release_camera_focus():
	var camera = get_camera()
	if camera:
		camera.focused_object = null


func screen_bump(dir=Vector2(), screenshake_amount=2.0, screenshake_time=0.1):
	var camera = get_camera()
	if camera:
		camera.bump(dir, screenshake_amount, screenshake_time)

func update_collision_boxes():
#	update_data()
	hurtbox.facing = get_facing()
	collision_box.facing = get_facing()
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

func fixed_dot(x1: String, y1: String, x2: String, y2: String) -> String:
	return fixed.add(fixed.mul(x1, x2), fixed.mul(y1, y2))

func fixed_inverse_lerp(a: String, b: String, v: String) -> String:
	return fixed.div(fixed.sub(v, a), fixed.sub(b, a))

func fixed_map(i_min: String, i_max: String, o_min: String, o_max: String, v: String):
	var t = fixed_inverse_lerp(i_min, i_max, v)
	return fixed.lerp_string(o_min, o_max, t)

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

func detect(obj):
	current_state().detect(obj)
	
func check_params(x, y):
	assert((x is int and y is int) or (x is String and y is String))

func set_x(x: int):
	chara.set_x(x)

func set_y(y: int):
	chara.set_y(y)

func get_center_position_float():
	return Vector2(position.x + collision_box.x, position.y + collision_box.y)
	
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


func set_snap_to_ground(snap: bool):
	chara.set_snap_to_ground(snap)

func get_snap_to_ground():
	return chara.get_snap_to_ground()

func get_data():
	return chara.get_data()

func get_active_hitboxes():
	var hitboxes = []
	if state_machine.state:
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

func set_gravity_modifier(modifier: String):
	chara.set_gravity_modifier(modifier)

func apply_grav_custom(grav: String, fall_speed: String):
	if gravity_enabled:
		chara.apply_grav_custom(grav, fall_speed)

func apply_grav():
	if gravity_enabled:
		chara.apply_grav()

func apply_fric():
	chara.apply_fric()

func apply_x_fric(fric):
	chara.apply_x_fric(fric)
	
func apply_y_fric(fric):
	chara.apply_y_fric(fric)

func limit_speed(limit):
	var vel = get_vel()
	if fixed.gt(fixed.vec_len(vel.x, vel.y), limit):
		var new_vel = fixed.normalized_vec_times(vel.x, vel.y, limit)
		set_vel(new_vel.x, new_vel.y)

func limit_x_speed(limit):
	var vel = get_vel()
	if fixed.gt(fixed.abs(vel.x), limit):
		var new_vel = fixed.mul(str(fixed.sign(vel.x)), limit)
		set_vel(new_vel, vel.y)

func limit_y_speed(limit):
	var vel = get_vel()
	if fixed.gt(fixed.abs(vel.y), limit):
		var new_vel = fixed.vec_mul(str(fixed.sign(vel.y)), limit)
		set_vel(vel.x, new_vel)

func get_object_dir(obj):
	var dir = Utils.int_sign(obj.get_pos().x - get_pos().x)
	if dir == 0:
		return get_facing_int()
	return dir

func get_object_dir_vec(obj):
	var my_pos = get_pos()
	var obj_pos = obj.get_pos()
	return fixed.normalized_vec(str(obj_pos.x - my_pos.x), str(obj_pos.y - my_pos.y))

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
	if !disabled:
		debug_text()
	
func debug_text():
	if debug_label:
		debug_label.text = ""
	if data:
		debug_info(data)

func debug_info(data):
	if debug_label:
		debug_label.text = debug_dict(debug_label.text, data)

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
	if !use_platforms:
		return chara.is_grounded()
	var grounded = chara.is_grounded() or current_state().name=="_LedgeGrab"
	if(!grounded and !(current_state().name=="HurtAerial" and float(get_vel().y)<=0)):
		var platforms = get_tree().get_nodes_in_group("Platform")
		for p in platforms:
			if(grounded):
				continue
			if(p.is_ghost==is_ghost):
				grounded = grounded or p.update_colliding(name)
	return grounded

func set_grounded(on):
	chara.set_grounded(on)

func add_pushback(pushback):
	chara.add_pushback(pushback)

func reset_pushback():
	chara.reset_pushback()

func update_grounded():
	chara.update_grounded()

func on_got_parried():
	hitlag_ticks += current_state().extra_parry_hitlag
	current_state().on_got_perfect_parried()

func get_state(state_name):
	return state_machine.get_state(state_name)

func on_got_blocked():
	current_state().on_got_blocked()

func on_got_parried_by(who):
	current_state().on_got_perfect_parried_by(who)
	for hitbox in get_active_hitboxes():
		hitbox.add_hit_object(who.obj_name)

func on_got_blocked_by(who):
	current_state().on_got_blocked_by(who)
	for hitbox in get_active_hitboxes():
		hitbox.add_hit_object(who.obj_name)

func deactivate_current_hitbox():
	for hitbox in get_active_hitboxes():
		if hitbox.active and hitbox.enabled and !hitbox.looping:
			hitbox.deactivate()
	
func deactivate_hitboxes():
	current_state().terminate_hitboxes()
	pass


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
	return Utils.fixed_vec2_string(force.x, force.y)
	
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

func distance_to(object: BaseObj):
	var p1 = get_pos()
	var p2 = object.get_pos()
	return fixed.vec_dist(str(p1.x), str(p1.y), str(p2.x), str(p2.y))

func tick():
	if current_tick <= 0:
		update_data()

	if hitlag_ticks > 0:
		hitlag_ticks -= 1
	else:
		normal_tick()
	
#	for particle in particles.get_children():
#		particle.tick()
	can_update_sprite = true
	update_collision_boxes()
	update_data()

func on_hit_ceiling():
	pass

func state_tick():
	var once = true
	while once or current_state().current_tick < 0:
		once = false
		state_machine.tick()
		if (!state_machine.state.endless) and state_machine.state.current_tick >= state_machine.state.anim_length and state_machine.queued_states == []:
			state_machine.queue_state(state_machine.state.fallback_state)
			state_machine.tick()

func get_states():
	return state_machine.states_map.values()

func fixed_deg_to_rad(n):
	assert(n is int or n is String)
	return fixed.mul(str(n), "0.01745329251")

func randi_():
	hash_rng()
	return logic_rng.randi()

func randi_range(a: int, b: int):
	hash_rng()
	return logic_rng.randi_range(a, b)

func randi_percent(n: int) -> bool:
	hash_rng()
	return logic_rng.randi_range(0, 99) < n

func randi_choice(choices: Array):
	hash_rng()
	return logic_rng.choose(choices)

func randi_weighted_choice(choices: Array, weights: Array):
	assert(weights == [] or choices.size() == weights.size())
	hash_rng()
	return choices[logic_rng.weighted_choice(choices, weights)]

func randi_static():
	hash_static_rng()
	return logic_rng_static.randi()

func randi_range_static(a: int, b: int):
	hash_static_rng()
	return logic_rng_static.randi_range(a, b)

func randi_percent_static(n: int) -> bool:
	hash_static_rng()
	return logic_rng_static.randi_range(0, 99) < n

func randi_choice_static(choices: Array):
	hash_static_rng()
	return logic_rng_static.choose(choices)

func randi_weighted_choice_static(choices: Array, weights: Array):
	assert(weights == [] or choices.size() == weights.size())
	hash_static_rng()
	return choices[logic_rng_static.weighted_choice(choices, weights)]

func should_hide_rng() -> bool:
	return is_ghost and (!Global.current_game.singleplayer or Global.current_game.spectating)

func tick_after():
	pass

func previous_state():
	return current_state()._previous_state()

func normal_tick():
	state_tick()
	update_data()
	current_tick += 1
	game_tick += 1
	update_grounded()

func get_knockback_force(hitbox):
	return fixed.normalized_vec_times(fixed.mul(hitbox.dir_x, str(hitbox.facing_int)), hitbox.dir_y, hitbox.knockback)

func compare(obj):
	var my_properties = get_property_list()
	var other_properties = obj.get_property_list()
	for property in my_properties:
#		print(property.name)
		if !is_instance_valid(self) or !is_instance_valid(obj):
			return
		var mine = get(property.name)
		var other = obj.get(property.name)
		if !(mine is Object) and !Utils.compare(mine, other):
#			print("property mismatch: %s\n mine: %s\ntheirs: %s\n\n" % [property.name, mine, other])
			pass
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")


func _draw():
#	draw_circle(to_local(get_pos_visual()), 5, Color.white)
	pass
