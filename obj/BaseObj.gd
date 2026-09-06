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
# Config dict propagated onto each spawned CustomHitEffect via _spawn_particle_effect.
# Schema: {sprite, show_particles, particles}. Set when applying a style with
# `hitspark == "custom"`; null otherwise (named-preset hitsparks ignore this).
var custom_hitspark_config = null

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
var roll_projectile_invulnerable = false

var state_variables = ["id", "roll_projectile_invulnerable", "grounded_attack_immune", "game_tick", "match_seed", "aerial_attack_immune", "last_object_hit", "can_update_sprite", "last_hit_frame", "damages_own_team", "ceiling_height", "has_ceiling", "has_projectile_parry_window", "always_parriable", "use_platforms", "gravity", "ground_friction", "air_friction", "max_ground_speed", "max_air_speed", "max_fall_speed", "projectile_invulnerable", "gravity_enabled", "default_hurtbox", "throw_invulnerable", "creator_name", "name", "obj_name", "stage_width", "hitlag_ticks", "combo_count", "invulnerable", "current_tick", "disabled", "state_interruptable", "state_hit_cancellable"]

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

# Modding hooks node (ObjHooks or a subclass). Created in _ready.
var hooks = null
var _init_hook_fired = false

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
	# Modding hook surface. The Hooks child is a scene ExtResource (obj/
	# BaseObj.tscn, script overridden per type in BaseChar/BaseProjectile.tscn),
	# so a mod's take_over_path swaps in its version with zero per-instance load.
	# Gated on ModLoader.active: with mods OFF, hooks stays null so every
	# `if hooks:` fire-site skips (the inert node is just left unused). _ready
	# auto-chains in Godot 3, so this runs for every subclass. See ObjHooks.gd.
	if ModLoader.active:
		hooks = get_node_or_null("Hooks")
		if hooks:
			hooks.host = self
			hooks.ready()

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
	if hooks:
		hooks.global_hitlag(round(amount))

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
	if hooks:
		hooks.refresh_hitboxes()

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
		# Inherit the per-style config too — without it _spawn_particle
		# _effect reads self.custom_hitspark_config=null and the spawned
		# CustomHitEffect falls back to defaults (no sprite frames /
		# particles / flip override), which looks like "custom hitsparks
		# aren't working" for any projectile-issued hit.
		custom_hitspark_config = creator.custom_hitspark_config
	# NOTE: the init hook is NOT fired here — BaseObj.init runs via a subclass's
	# super call (e.g. Fighter.init calls .init(pos) first, then sets hp), so
	# firing here would be before the subclass finished initializing. It's fired
	# by _fire_init_hook() at the engine call sites, once init() has fully
	# returned. See _fire_init_hook.

# Fires the modding init hook exactly once, after init() has FULLY returned
# (including subclass init like Fighter's hp setup). Called by the engine right
# after each init() call site, so it never fires mid-init. Idempotent.
func _fire_init_hook():
	if hooks and not _init_hook_fired:
		_init_hook_fired = true
		hooks.init()

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
	if hooks:
		hooks.change_state(state_name, state_data)
	state_machine._change_state(state_name, state_data, enter, exit)

func obj_from_name(name):
	if name is String and name in objs_map:
		var obj = objs_map[name]
		# is_instance_valid (not just != null): once a reclaimed projectile husk
		# is freed its reference is non-null but invalid, and touching .disabled
		# on it would error. See game.reclaim_disabled_husks / BaseProjectile.
		if is_instance_valid(obj):
			if !obj.disabled:
				return obj

func _on_hit_something(obj, hitbox):
	if last_hit_frame == current_tick:
		if hit_fighter_last():
			return
	last_object_hit = obj.obj_name
	last_hit_frame = current_tick
	if hooks:
		hooks.hit_something(obj, hitbox)

func hit_fighter_last():
	return last_object_hit == get_opponent().obj_name or last_object_hit == get_fighter().obj_name

func can_be_thrown():
	return !throw_invulnerable

func _copy_state_variables_to(o: BaseObj):
	for variable in state_variables:
		var v = get(variable)
		if v is Array or v is Dictionary:
			o.set(variable, v.duplicate(true))
		else:
			o.set(variable, v)

func copy_to(o: BaseObj):
	if !initialized:
		init()
		_fire_init_hook()
	var current_state = current_state()
#	print(current_state().property_list)
	o.state_machine.starting_state = current_state.name
	o.spawn_data = current_state.copy_data()
	o.set_pos(get_pos().x, get_pos().y)
	if creator_name and o.objs_map.has(creator_name):
		o.creator = o.objs_map[creator_name]
	o.init()
	o._fire_init_hook()
	o.update_data()
	_copy_state_variables_to(o)

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
	# _enter on the ghost may re-trigger start_X_invulnerability calls that the
	# real instance has long since ended. Explicitly re-sync all invul flags
	# from real (post-_enter) so prediction matches.
	o.projectile_invulnerable = projectile_invulnerable
	o.invulnerable = invulnerable
	o.throw_invulnerable = throw_invulnerable
	o.aerial_attack_immune = aerial_attack_immune
	o.grounded_attack_immune = grounded_attack_immune

	chara.copy_to(o.chara)
	o.set_facing(get_facing_int())
	# Explicit vel re-sync. Some states' _enter mutate cross-character chara
	# state — e.g. StickyBombThrow._enter calls host.opponent.reset_momentum(),
	# which clobbers the opponent's chara vel during the ghost change_state
	# fast-forward above. The chara.copy_to one line up doesn't reach the
	# OTHER character's chara, so we need each obj's copy_to to also pin its
	# own vel from live state at the end. Pairs with the post-_enter invul
	# resync above (same problem class — _enter side effects in copy_to).
	# Read straight from chara via get_data() — self.data is the cached
	# snapshot and may not reflect mid-copy_to chara writes, so get_vel()
	# would feed stale numbers into the ghost.
	var live_object_data = get_data().object_data
	o.set_vel(live_object_data.vel_x, live_object_data.vel_y)
	# Force a data refresh on the ghost after the vel sync. `set_vel` writes
	# directly to chara, but `get_vel()` reads from the cached `data` snapshot
	# that only refreshes on update_data(). Without this, downstream code in
	# BaseChar.copy_to / state.copy_hurtbox_states / etc. that reads o.get_vel
	# (or any other data field) sees stale pre-set_vel values, which manifested
	# as ghost prediction not picking up projectile knockback at turn start.
	o.update_data()
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

	if hooks:
		hooks.copy_to(o)

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
	obj.objs_map = objs_map
	obj.is_ghost = is_ghost
	# Name is assigned by Game.on_object_spawned (which holds the spawn counter).
	obj.spawn_data = data
	obj.stage_width = stage_width
	var pos = get_pos()
	if local:
		obj.set_pos(pos.x + pos_x * (get_facing_int() if relative else 1), pos.y + pos_y)
	else:
		obj.set_pos(pos_x, pos_y)
	obj.set_facing(get_facing_int())
	obj.id = id
	emit_signal("object_spawned", obj)
	if hooks:
		hooks.spawn_object(obj)
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

func start_roll_projectile_invulnerability():
	roll_projectile_invulnerable = true
	
func end_roll_projectile_invulnerability():
	roll_projectile_invulnerable = false

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
	# Forward the spawning entity's custom hitspark config (if any) onto the
	# instance before it enters the tree. CustomHitEffect.gd reads this in
	# its _ready to configure sprite frames + particle settings without
	# round-tripping through PackedScene.pack.
	# Only actual custom hitsparks (CustomHitEffect, which declares the
	# `custom_config` property) should receive the player's hitspark config and
	# its flip_when_facing_left orientation override. Every other particle a
	# character spawns — geyser jets, telekinesis debris, etc. — must be left
	# alone, or the hitspark's flip leaks onto them and mirrors/inverts them
	# when facing left.
	var cfg = self.get("custom_hitspark_config")
	var is_custom_hitspark = cfg != null and "custom_config" in obj
	if is_custom_hitspark:
		obj.set("custom_config", cfg)
	add_child(obj)
	obj.tick()
	var facing = -1 if dir.x < 0 else 1
	obj.position = pos
	# Hitsparks default to a 180° rotation when facing left so symmetric
	# sprites read correctly mirrored. Custom hitsparks can opt into a pure
	# horizontal flip instead (no rotation) — useful for asymmetric art where
	# the rotation feels wrong. Flag rides on the custom_hitspark_config dict.
	var flip_only = is_custom_hitspark and facing < 0 and cfg is Dictionary and cfg.get("flip_when_facing_left", false)
	if facing < 0 and not flip_only:
		obj.rotation = (dir * Vector2(-1, -1)).angle()
	else:
		obj.rotation = dir.angle()
	obj.scale.x = facing
	# Propagate `facing` to any CustomTrailParticle children — same hook the
	# aura path uses (BaseChar._apply_aura_state) to flip gravity_x and the
	# emission angle when the character faces left. Without this, hitspark
	# particles always emit as if facing right regardless of the hit dir.
	for child in obj.get_children():
		if child is CustomTrailParticle:
			child.facing = facing
	remove_child(obj)

	emit_signal("particle_effect_spawned", obj)
	if hooks:
		hooks.spawn_particle(obj)
	return obj

func get_camera():
	if is_ghost:
		return null
	for cam in get_tree().get_nodes_in_group("Camera"):
		if is_instance_valid(cam) and is_instance_valid(cam.get_parent()) and !cam.get_parent().is_ghost:
			return cam
	return null

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
	if is_instance_valid($Flip):
		$Flip.scale.x = -1 if facing < 0 else 1
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
	# Physics integrate consumed any pending forces and updated chara vel —
	# refresh the data cache so any get_vel/get_pos read in the same tick
	# (or downstream consumers in the same call chain) sees fresh values.
#	if initialized:
#		update_data()

func apply_forces_no_limit():
	chara.apply_forces_no_limit()
#	if initialized:
#		update_data()

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
		var new_vel = fixed.mul(str(fixed.sign(vel.y)), limit)
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
	if hooks:
		hooks.on_got_parried()

func get_state(state_name):
	return state_machine.get_state(state_name)

func on_got_blocked():
	var state = current_state()
	state.on_got_blocked()
	state.was_blocked = true
	if state.get("number_of_hits_blocked") != null:
		state.number_of_hits_blocked += 1
	if hooks:
		hooks.on_got_blocked()

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



func is_invulnerable_to(hitbox, attacker):
	var grounded = is_grounded()
	var otg = is_otg()
	
	if (hitbox is ThrowBox) and !can_be_thrown():
		return true
	if (!hitbox.hits_vs_aerial and !grounded) or (!hitbox.hits_vs_grounded and grounded):
		return true
	if !otg and !hitbox.hits_vs_standing:
		return true
	if otg and not hitbox.hits_otg:
		return true
	if hitbox.already_hit_object(self):
		return true
	if attacker:
		if !attacker.is_grounded():
			if aerial_attack_immune:
				return true
		else:
			if grounded_attack_immune:
				return true
		if attacker.id == id and !hitbox.allowed_to_hit_own_team:
			return true
	
	return false



func hit_by(hitbox: Hitbox):
	emit_signal("got_hit")
	if hooks:
		hooks.hit_by(hitbox)

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
	if hooks:
		hooks.pre_tick()
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
	if hooks:
		hooks.post_tick()

func on_hit_ceiling():
	if hooks:
		hooks.on_hit_ceiling()

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

# --- Limb Finder runtime API ---
# Returns the limb_data dictionary stored on the node by the Limb Finder plugin.
# Format: { limb_name: { Texture: { x, y, dir_x, dir_y, flipped } } }
func get_limb_data() -> Dictionary:
	if has_meta("limb_data"):
		var d = get_meta("limb_data")
		if d is Dictionary:
			return d
	return {}

# The currently-active sprite node used for limb lookups. Override in
# subclasses for objects that swap which AnimatedSprite is active
# (Mutant's TwistAttackSprite, Wizard's LiftoffSprite, etc).
# Returning a different node also makes `get_limb_pos`/`get_limb_dir` apply
# THAT node's transform — including rotation/scale/flip.
func get_current_limb_sprite_node():
	return sprite

func get_current_limb_sprite_texture():
	var s = get_current_limb_sprite_node()
	if s and s is AnimatedSprite and s.frames and s.frames.has_animation(s.animation):
		return s.frames.get_frame(s.animation, s.frame)
	return null

# Per-limb override hook. Subclasses can return a different sprite for
# specific limbs — e.g. Cowboy's gun-shoot arm sprite for LeftHand/RightHand
# while the body is on the main sprite. Defaults to the same sprite for all
# limbs.
func get_current_limb_sprite_node_for(_limb_name: String):
	return get_current_limb_sprite_node()

func get_current_limb_sprite_texture_for(limb_name: String):
	var s = get_current_limb_sprite_node_for(limb_name)
	if s and s is AnimatedSprite and s.frames and s.frames.has_animation(s.animation):
		return s.frames.get_frame(s.animation, s.frame)
	return null

func get_limb_entry(limb_name: String):
	var data = get_limb_data()
	if !data.has(limb_name):
		return null
	var by_tex = data[limb_name]
	var tex = get_current_limb_sprite_texture_for(limb_name)
	if tex and by_tex.has(tex):
		var e = by_tex[tex]
		# Entries with `absent: true` mean the user explicitly said this limb
		# isn't on this sprite — treat the same as no data for runtime queries.
		if e is Dictionary and e.get("absent", false):
			return null
		return e
	return null

# Returns true if the user explicitly marked this limb as absent on the
# current sprite. Differs from "no data" — use this to hide visuals attached
# to the limb when the sprite doesn't contain it.
func is_limb_absent_on_current_sprite(limb_name: String) -> bool:
	var data = get_limb_data()
	if !data.has(limb_name):
		return false
	var by_tex = data[limb_name]
	var tex = get_current_limb_sprite_texture_for(limb_name)
	if tex and by_tex.has(tex):
		var e = by_tex[tex]
		return e is Dictionary and e.get("absent", false)
	return false

# World-space limb position. Accounts for the sprite's full transform chain:
# parent transforms (Flip's scale-x for facing), the sprite's own
# position/rotation/scale, sprite.offset, sprite.centered, and flip_h/flip_v.
func get_limb_pos(limb_name: String):
	var e = get_limb_entry(limb_name)
	if e == null:
		return null
	var s = get_current_limb_sprite_node_for(limb_name)
	var tex = get_current_limb_sprite_texture_for(limb_name)
	if s == null or tex == null:
		return Vector2(e.x, e.y)
	return _limb_pixel_to_world(s, tex, Vector2(e.x, e.y))

# World-space limb direction (unit vector). Applies sprite rotation/scale/flip
# but NOT translation (it's a direction, not a point).
func get_limb_dir(limb_name: String):
	var e = get_limb_entry(limb_name)
	if e == null:
		return null
	var s = get_current_limb_sprite_node_for(limb_name)
	if s == null:
		return Vector2(e.dir_x, e.dir_y)
	return _limb_dir_to_world(s, Vector2(e.dir_x, e.dir_y))

# Limb position in the sprite's parent frame — typically Flip-local, since
# `Particles` (where auras live) is a sibling of the sprite under Flip. This
# lets Flip's facing-mirror transform automatically position auras at the
# mirrored anatomical limb when the character faces left, with no double
# flipping.
func get_limb_local_pos(limb_name: String):
	var e = get_limb_entry(limb_name)
	if e == null:
		return null
	var s = get_current_limb_sprite_node_for(limb_name)
	var tex = get_current_limb_sprite_texture_for(limb_name)
	if s == null or tex == null:
		return Vector2(e.x, e.y)
	var local = Vector2(e.x, e.y)
	if "centered" in s and s.centered:
		local -= tex.get_size() / 2
	if "flip_h" in s and s.flip_h:
		local.x = -local.x
	if "flip_v" in s and s.flip_v:
		local.y = -local.y
	if "offset" in s:
		local += s.offset
	return s.transform.xform(local)

# Limb direction in the sprite's parent frame (typically Flip-local). Applies
# the sprite's local transform (rotation, scale) and flip_h/flip_v on top of
# the texture-pixel dir, so a rotating sprite (e.g. Cowboy's gun-shoot arm
# pivoting on aim angle) gets its rotation reflected in the result.
func get_limb_sprite_parent_dir(limb_name: String):
	var e = get_limb_entry(limb_name)
	if e == null:
		return null
	var s = get_current_limb_sprite_node_for(limb_name)
	var d = Vector2(e.dir_x, e.dir_y)
	if s == null:
		return d
	if "flip_h" in s and s.flip_h:
		d.x = -d.x
	if "flip_v" in s and s.flip_v:
		d.y = -d.y
	return s.transform.basis_xform(d)

# Limb direction in this BaseObj's local frame (unit vector).
# Useful for orienting child nodes attached to the character (aura particles etc).
func get_limb_local_dir(limb_name: String):
	var e = get_limb_entry(limb_name)
	if e == null:
		return null
	var s = get_current_limb_sprite_node_for(limb_name)
	var d = Vector2(e.dir_x, e.dir_y)
	if s == null:
		return d
	if "flip_h" in s and s.flip_h:
		d.x = -d.x
	if "flip_v" in s and s.flip_v:
		d.y = -d.y
	var world_d = s.global_transform.basis_xform(d)
	return self.global_transform.basis_xform_inv(world_d)

# True iff there's any entry (present or absent) for this limb on the current sprite.
func has_limb_entry_on_current_sprite(limb_name: String) -> bool:
	var data = get_limb_data()
	if !data.has(limb_name):
		return false
	var by_tex = data[limb_name]
	var tex = get_current_limb_sprite_texture_for(limb_name)
	return tex != null and by_tex.has(tex)

# Texture-pixel position of the limb (no transforms applied). Useful if you
# want to do math in the original sprite-art space.
func get_limb_pixel_pos(limb_name: String):
	var e = get_limb_entry(limb_name)
	if e == null:
		return null
	return Vector2(e.x, e.y)

# Texture-pixel direction (no transforms applied).
func get_limb_pixel_dir(limb_name: String):
	var e = get_limb_entry(limb_name)
	if e == null:
		return null
	return Vector2(e.dir_x, e.dir_y)

func is_limb_flipped(limb_name: String) -> bool:
	var e = get_limb_entry(limb_name)
	if e == null:
		return false
	return e.get("flipped", false)

func _limb_pixel_to_world(sprite_node: Node2D, tex: Texture, pixel_pos: Vector2) -> Vector2:
	var local = pixel_pos
	if "centered" in sprite_node and sprite_node.centered:
		local -= tex.get_size() / 2
	# flip_h / flip_v on the sprite mirror the texture in place; they don't
	# show up in the transform, so we mirror the local point manually.
	if "flip_h" in sprite_node and sprite_node.flip_h:
		local.x = -local.x
	if "flip_v" in sprite_node and sprite_node.flip_v:
		local.y = -local.y
	if "offset" in sprite_node:
		local += sprite_node.offset
	return sprite_node.global_transform.xform(local)

func _limb_dir_to_world(sprite_node: Node2D, dir: Vector2) -> Vector2:
	var d = dir
	if "flip_h" in sprite_node and sprite_node.flip_h:
		d.x = -d.x
	if "flip_v" in sprite_node and sprite_node.flip_v:
		d.y = -d.y
	return sprite_node.global_transform.basis_xform(d)

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
