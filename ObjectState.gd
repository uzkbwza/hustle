extends StateInterface

class_name ObjectState

signal state_started()
signal state_ended()

export var _c_Physics = 0
export var apply_forces = false
export var apply_fric = false
export var apply_grav = false

export var _c_Animation_and_Length = 0
export var fallback_state = "Wait"
export var sprite_animation = ""
export var anim_length = 1
export var sprite_anim_length = -1
export var ticks_per_frame = 1
export var loop_animation = false
export var endless = false

export var _c_Static_Force = 0
export var force_dir_x = "0.0"
export var force_dir_y = "0.0"
export var force_speed = "0.0"
export var force_tick = 0

export var _c_Enter_Static_Force = 0
export var enter_force_dir_x = "0.0"
export var enter_force_dir_y = "0.0"
export var enter_force_speed = "0.0"
export var reset_momentum = false

export var _c_Particles = 0
export(PackedScene) var particle_scene = null
export var particle_position = Vector2()
export var spawn_particle_on_enter = false

export var _c_TimedParticles = 0
export(PackedScene) var timed_particle_scene = null
export var timed_particle_position = Vector2()
export var timed_spawn_particle_tick = 1

export var _c_Sfx = 0
export(AudioStream) var enter_sfx = null
export var enter_sfx_volume = -15.0
export(AudioStream) var sfx = null
export var sfx_tick = 1
export var sfx_volume = -15.0

export var _c_Projectiles = 0
export(PackedScene) var projectile_scene
export var projectile_tick = 1
export var projectile_pos_x = 0
export var projectile_pos_y = 0
export var projectile_local_pos = true



var enter_sfx_player
var sfx_player

var current_tick = -1
var fixed

var anim_name

var has_hitboxes = false

var hitbox_start_frames = {
}

var frame_methods = []
var max_tick = -1

func apply_enter_force():
	if enter_force_speed != "0.0":
		var force = xy_to_dir(enter_force_dir_x, enter_force_dir_y, enter_force_speed, "1.0")
#		force.y = host.fixed.mul(force.y, "2.0")
		host.apply_force_relative(force.x, force.y)

func _on_hit_something(_obj, _hitbox):
	pass

func get_projectile_pos():
	return { "x": projectile_pos_x, "y": projectile_pos_y }

func get_projectile_data():
	return null

func process_projectile(_projectile):
	pass

func get_active_hitboxes():
	var hitboxes = []
	for start_frame in hitbox_start_frames:
		var items = hitbox_start_frames[start_frame]
		for item in items:
			if item is Hitbox:
				hitboxes.append(item)
	return hitboxes

func _tick_before():
	pass

func _tick_shared():
#	if current_tick == -1:
#		if has_method("_frame_0"):
#			call("_frame_0")
	
	if current_tick == -1:
		if spawn_particle_on_enter and particle_scene:
			spawn_particle_relative(particle_scene, particle_position)
		apply_enter_force()

	if current_tick < anim_length or endless:
		current_tick += 1
		update_sprite_frame()
		if hitbox_start_frames.has(current_tick + 1):
			for hitbox in hitbox_start_frames[current_tick + 1]:
				activate_hitbox(hitbox)
		for hitbox in get_active_hitboxes():
			hitbox.facing = host.get_facing()
			if hitbox.active:
				hitbox.tick()
			else:
				deactivate_hitbox(hitbox)
		if current_tick == sfx_tick and sfx_player and !ReplayManager.resimulating:
			sfx_player.play()
		if current_tick == force_tick:
			if force_speed != "0.0":
				var force = xy_to_dir(force_dir_x, force_dir_y, force_speed, "1.0")
		#		force.y = host.fixed.mul(force.y, "2.0")
				host.apply_force_relative(force.x, force.y)

		if current_tick == projectile_tick:
			if projectile_scene:
				var pos = get_projectile_pos()
				var obj = host.spawn_object(projectile_scene, pos.x, pos.y, true, get_projectile_data(), projectile_local_pos)
				process_projectile(obj)

		if current_tick == timed_spawn_particle_tick:
			if timed_particle_scene:
				spawn_particle_relative(timed_particle_scene, timed_particle_position)

		var new_max = false
		if current_tick > max_tick:
			max_tick = current_tick
			new_max = true
		
		if host.is_ghost or new_max or current_tick in frame_methods:
			var method_name = "_frame_" + str(current_tick)
			# create methods called "_frame_1" or "_frame_27" etc to execute actions on those frames.
			if has_method(method_name):
				if not (current_tick in frame_methods):
					frame_methods.append(current_tick)
				var next_state = call(method_name)
				if next_state != null:
					return next_state
			new_max = false

	
	if apply_fric:
		host.apply_fric()
	if apply_grav:
		host.apply_grav()
	if apply_forces:
		host.apply_forces()

func _tick_after():
	for hitbox in get_active_hitboxes():
		var pos = host.get_pos()
		hitbox.update_position(pos.x, pos.y)

func copy_data():
	var d = null
	if data:
		if data is Dictionary or data is Array:
			d = data.duplicate()
		else:
			d = data
	return d

func copy_to(state: ObjectState):
	var properties = get_script().get_script_property_list()
	for variable in properties:
		var value = get(variable.name)
		if not (value is Object or value is Array or value is Dictionary):
			if value:
				state.set(variable.name, value)
	state.data = copy_data()

func activate_hitbox(hitbox):
	hitbox.activate()

func terminate_hitboxes():
	for hitbox in get_active_hitboxes():
		hitbox.deactivate()

func deactivate_hitbox(hitbox):
#	active_hitboxes.erase(hitbox)
	pass

func init():
	connect("state_started", host, "on_state_started", [self])
	connect("state_ended", host, "on_state_ended", [self])
	fixed = host.fixed
	anim_name = sprite_animation if sprite_animation else state_name
	if sprite_anim_length < 0:
		if host.sprite.frames.has_animation(anim_name):
			sprite_anim_length = host.sprite.frames.get_frame_count(anim_name)
		else:
			sprite_anim_length = anim_length
	setup_hitboxes()
	call_deferred("setup_audio")

func setup_audio():
	if enter_sfx:
		enter_sfx_player = VariableSound2D.new()
		add_child(enter_sfx_player)
		enter_sfx_player.bus = "Fx"
		enter_sfx_player.stream = enter_sfx
		enter_sfx_player.volume_db = enter_sfx_volume

	if sfx:
		sfx_player = VariableSound2D.new()
		add_child(sfx_player)
		sfx_player.bus = "Fx"
		sfx_player.stream = sfx
		sfx_player.volume_db = sfx_volume

func setup_hitboxes():
	var hitboxes = []
	for child in get_children():
		if child is Hitbox:
			hitboxes.append(child)
			host.hitboxes.append(child)
	for hitbox in hitboxes:
		hitbox.init()
		has_hitboxes = true
		hitbox.host = host
		if hitbox.start_tick >= 0:
			if hitbox_start_frames.has(hitbox.start_tick):
				hitbox_start_frames[hitbox.start_tick].append(hitbox)
			else:
				hitbox_start_frames[hitbox.start_tick] = [hitbox]
		hitbox.connect("hit_something", self, "__on_hit_something")
		hitbox.connect("got_parried", self, "__on_got_parried")
		for hitbox2 in hitboxes:
			if hitbox2.group == hitbox.group:
				hitbox.grouped_hitboxes.append(hitbox2)
		

func __on_hit_something(obj, hitbox):
	if active:
		_on_hit_something(obj, hitbox)

func __on_got_parried():
	if active:
		_got_parried()

func _got_parried():
	pass

func spawn_particle_relative(scene: PackedScene, pos=Vector2(), dir=Vector2.RIGHT):
	var p = host.get_pos_visual()
	host.spawn_particle_effect(scene, p + pos, dir)

func _enter_shared():
	if reset_momentum:
		host.reset_momentum()
	current_tick = -1
	if enter_sfx_player and !ReplayManager.resimulating:
		enter_sfx_player.play()
	emit_signal("state_started")
	
func xy_to_dir(x, y, mul="1.0", div="100.0"):
	return host.xy_to_dir(x, y, mul, div)

func update_sprite_frame():
	if ReplayManager.resimulating:
		return
	if !host.sprite.frames.has_animation(anim_name):
		return
	if host.sprite.animation != anim_name:
		host.sprite.animation = anim_name
		host.sprite.frame = 0
	var sprite_tick = current_tick / ticks_per_frame
#	var frame = host.fixed.int_map((current_tick % sprite_anim_length) if loop_animation else Utils.int_min(current_tick, sprite_anim_length), 0, sprite_anim_length, 0, host.sprite.frames.get_frame_count(host.sprite.animation))
	var frame = (sprite_tick % sprite_anim_length) if loop_animation else Utils.int_min(sprite_tick, sprite_anim_length)
	host.sprite.frame = frame
