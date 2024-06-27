extends StateInterface

class_name ObjectState

signal state_started()
signal state_ended()

export var _c_Physics = 0
export var apply_forces = false
export var apply_fric = false
export var apply_grav = false
export var reset_momentum = false
export var reset_x_momentum = false
export var reset_y_momentum = false

export var _c_Custom_Physics = 0
export var apply_custom_x_fric = false
export var apply_custom_y_fric = false
export var apply_custom_grav = false
export var apply_forces_no_limit = false


export var custom_x_fric = "0.0"
export var custom_y_fric = "0.0"
export var custom_grav = "0.0"
export var custom_grav_max_fall_speed = "0.0"

export var apply_custom_limits = false

export var custom_max_air_speed = "15.0"
export var custom_max_ground_speed = "10.0"


export var _c_Animation_and_Length = 0
export var fallback_state = "Wait"
export var sprite_animation = ""
export var anim_length = 1
export var sprite_anim_length = -1
export var ticks_per_frame = 1
export var loop_animation = false
export var animation_loop_start = 0
export var absolute_loop = false
export var refresh_loop = true
export var endless = false
export var disable_at_end = false

export var _c_Static_Force = 0
export var force_dir_x = "0.0"
export var force_dir_y = "0.0"
export var force_speed = "0.0"
export var force_tick = 0

export var _c_Enter_Static_Force = 0
export var enter_force_dir_x = "0.0"
export var enter_force_dir_y = "0.0"
export var enter_force_speed = "0.0"


export var _c_Particles = 0
export(PackedScene) var particle_scene = null
export var particle_position = Vector2()
export var spawn_particle_on_enter = false

export var _c_Screenshake = 0
export var state_screenshake_tick = -1
export var state_screenshake_dir = Vector2()
export var state_screenshake_length = 0.25
export var state_screenshake_amount = 10

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
export var projectile_match_facing = false

export var _c_Other = 0
export var extra_parry_hitlag = 0


export var _c_Flip = 0
export var flip_frame = -1
export var force_same_direction_as_previous_state = false

export var _c_Meta = 0
export var host_commands = {
}

export var earliest_hitbox = 0
var earliest_hitbox_node = null
var is_guard_break = false

export var _c_Auto = 0
export var throw_positions: Dictionary = {}

var enter_sfx_player
var sfx_player

var is_grab = false
var current_tick = -1 
var current_real_tick = -1
var start_tick = -1
var last_facing = 1
var fixed
var native

var anim_name
var property_list: PoolStringArray

var has_hitboxes = false

var current_hurtbox = null
var same_as_last_state = false

var host_command_nodes = {
	
}

var hitbox_start_frames = {
}

var hurtbox_state_change_frames = {
	
}

var limb_hurtboxes = []

var all_hitbox_nodes = []
var frame_methods = []
var frame_methods_shared = []
var max_tick = -1
var max_tick_shared = -1
var exit_tick = -1

func apply_enter_force():
	if enter_force_speed != "0.0":
		var force = xy_to_dir(enter_force_dir_x, enter_force_dir_y, enter_force_speed, "1.0")
#		force.y = host.fixed.mul(force.y, "2.0")
		host.apply_force_relative(force.x, force.y)

func apply_timed_force():
	if force_speed != "0.0":
		var force = xy_to_dir(force_dir_x, force_dir_y, force_speed, "1.0")
#		force.y = host.fixed.mul(force.y, "2.0")
		host.apply_force_relative(force.x, force.y)

func _on_hit_something(obj, hitbox):
	if hitbox.followup_state != "" and obj.is_in_group("Fighter"):
		queue_state_change(hitbox.followup_state)

func get_projectile_pos():
	return { "x": projectile_pos_x, "y": projectile_pos_y }

func get_projectile_data():
	return null

func process_projectile(_projectile):
	pass

func get_active_hitboxes():
	var hitboxes = []
	var pos = host.get_pos()
	for start_frame in hitbox_start_frames:
		var items = hitbox_start_frames[start_frame]
		for hitbox in items:
			if hitbox is Hitbox:
				if hitbox.active:
					hitboxes.append(hitbox)
	for hitbox in all_hitbox_nodes:
			if hitbox is Hitbox:
				if hitbox.active and !(hitbox in hitboxes):
					hitboxes.append(hitbox)
	return hitboxes

func get_active_hurtboxes():
	var hurtboxes = []
	for child in get_children():
		if child is LimbHurtbox:
			if is_hurtbox_active(child):
				hurtboxes.append(child)
	return hurtboxes

func is_hurtbox_active(hurtbox: LimbHurtbox):
	var after_start = hurtbox.start_tick <= 0
	if !after_start:
		if current_tick + 1 > hurtbox.start_tick:
			after_start = true
	var before_end = hurtbox.endless
	if !before_end:
		if current_tick <= hurtbox.start_tick + hurtbox.active_ticks:
			before_end = true
	return after_start and before_end

func _tick_before():
	pass

func process_feint():
	return fallback_state

func spawn_exported_projectile():
	if projectile_scene:
		var pos = get_projectile_pos()
		var obj = host.spawn_object(projectile_scene, pos.x, pos.y, true, get_projectile_data(), projectile_local_pos)
		if projectile_match_facing:
			obj.set_facing(host.get_facing_int())
		process_projectile(obj)

func spawn_enter_particle():
	var pos = particle_position
	pos.x *= host.get_facing_int()
	spawn_particle_relative(particle_scene, pos, Vector2.RIGHT * host.get_facing_int())

func _tick_shared():
#	if current_tick == -1:
#		if has_method("_frame_0"):
#			call("_frame_0")

	if current_tick == -1:
		if spawn_particle_on_enter and particle_scene:
			spawn_enter_particle()
		apply_enter_force()

	current_real_tick += 1
	if current_tick < anim_length or endless:
		current_tick += 1
#		if process_hitboxes() == true:
		process_hitboxes()
		process_hurtboxes()
#			return process_feint()
		if host.can_update_sprite:
			update_sprite_frame()
		if current_tick == sfx_tick and sfx_player and !ReplayManager.resimulating:
			sfx_player.play()
		if current_tick == force_tick:
			apply_timed_force()

		if current_tick == projectile_tick:
			spawn_exported_projectile()

		if current_tick == timed_spawn_particle_tick:
			if timed_particle_scene:
				var pos = timed_particle_position
				pos.x *= host.get_facing_int()
				spawn_particle_relative(timed_particle_scene, pos, Vector2.RIGHT * host.get_facing_int())

		if current_tick == state_screenshake_tick:
			host.screen_bump(state_screenshake_dir, state_screenshake_amount, state_screenshake_length)

		if current_tick == flip_frame:
			host.turn_around()

		if current_tick in host_commands:
			var command = host_commands[current_tick]
			if command is Array:
				if !command.empty():
					host.callv(command[0], command.slice(1, command.size() - 1))
			elif command is String:
				host.call(command)
		
		if current_tick in host_command_nodes:
			var commands = host_command_nodes[current_tick]
			for command in commands:
				host.callv(command.command, command.args)

		var new_max = false
		var new_max_shared = false
		if current_tick > max_tick:
			max_tick = current_tick
			new_max = true
			
		if current_tick > max_tick_shared:
			max_tick_shared = current_tick
			new_max_shared = true
		
		
		if host.is_ghost or new_max or current_tick in frame_methods_shared:
			var method_name = "_frame_" + str(current_tick) + "_shared"
			# create methods called "_frame_1" or "_frame_27" etc to execute actions on those frames.
			if has_method(method_name):
				if not (current_tick in frame_methods_shared):
					frame_methods_shared.append(current_tick)
				var next_state = call(method_name)
				if next_state != null:
					return next_state
			new_max = false
			
		if host.is_ghost or new_max_shared or current_tick in frame_methods:
			var method_name = "_frame_" + str(current_tick)
			# create methods called "_frame_1" or "_frame_27" etc to execute actions on those frames.
			if has_method(method_name):
				if not (current_tick in frame_methods):
					frame_methods.append(current_tick)
				var next_state = call(method_name)
				if next_state != null:
					return next_state
			new_max_shared = false


	if apply_fric:
		host.apply_fric()
	if apply_grav:
		host.apply_grav()
	if apply_custom_x_fric:
		host.apply_x_fric(custom_x_fric)
	if apply_custom_y_fric:
		host.apply_y_fric(custom_y_fric)
	if apply_custom_grav:
		host.apply_grav_custom(custom_grav, custom_grav_max_fall_speed)
	if apply_forces:
		if apply_forces_no_limit:
			host.apply_forces_no_limit()
		
		elif apply_custom_limits:
			if host.is_grounded():
				host.limit_x_speed(custom_max_ground_speed)
			else:
				host.limit_x_speed(custom_max_air_speed)
			host.apply_forces_no_limit()
		else:
			host.apply_forces()

func process_hitboxes():
	host.update_data()
	var pos = host.get_pos()
	if hitbox_start_frames.has(current_tick + 1):
		for hitbox in hitbox_start_frames[current_tick + 1]:
			if !hitbox.activated:
				continue
			hitbox.update_position(pos.x, pos.y)
			activate_hitbox(hitbox)
			if hitbox is Hitbox:
				if hitbox.hitbox_type == Hitbox.HitboxType.ThrowHit:
					hitbox.hit(host.opponent)
					hitbox.deactivate()
	for hitbox in get_active_hitboxes():
		hitbox.update_position(pos.x, pos.y)
		hitbox.facing = host.get_facing()
		if hitbox.active:
			hitbox.tick()
		else:
			deactivate_hitbox(hitbox)

func process_hurtboxes():

	if current_hurtbox:
		current_hurtbox.tick(host)
	if current_tick in hurtbox_state_change_frames:
		if current_hurtbox:
			current_hurtbox.end(host)
		current_hurtbox = hurtbox_state_change_frames[current_tick]
		current_hurtbox.start(host)
	var pos = host.get_pos()
	for hurtbox in limb_hurtboxes:
		if hurtbox is LimbHurtbox:
			hurtbox.active = is_hurtbox_active(hurtbox)
			hurtbox.facing = host.get_facing()
			hurtbox.update_position(pos.x, pos.y)
	host.hurtbox.facing = host.get_facing()


func copy_data():
	var d = null
	if data:
		if data is Dictionary or data is Array:
			d = data.duplicate()
		else:
			d = data
	return d

#func set(key, value):
#	if key == "test":
#		print("setting %s to %s" % [key, value])
#	.set(key, value)

func _copy_to(state: ObjectState):
	state.data = copy_data()
	state.current_real_tick = current_real_tick
	state.current_tick = current_real_tick
	var pos = host.get_pos()
	for h in get_children():
		if(h is Hitbox):
			h.copy_to(state.get_node(h.name))
			h.update_position(pos.x, pos.y)
#	for h in all_hitbox_nodes:
#		if(h is Hitbox):
#			h.copy_to(state.get_node(h.name))
#			h.update_position(pos.x, pos.y)

func copy_to(state: ObjectState):
#	print(get_script().get_script_property_list())
	state.property_list = property_list
#	print(property_list)
	native.copy_state(self, state)
	_copy_to(state)

func copy_hurtbox_states(state: ObjectState):
	for i in range(get_child_count()):
		var child = get_child(i)
		if child is HurtboxState:
			if child.started:
				state.get_child(i).start(state.host)
				state.current_hurtbox = state.get_child(i)
			child.copy_to(state.get_child(i))

func activate_hitbox(hitbox):
	hitbox.facing = host.get_facing()
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
	native = host.native
	anim_name = sprite_animation if sprite_animation else state_name
	if sprite_anim_length < 0:
		if host.sprite.frames.has_animation(anim_name):
			sprite_anim_length = host.sprite.frames.get_frame_count(anim_name)
		else:
			sprite_anim_length = anim_length
	setup_hitboxes()
	setup_hurtboxes()
	call_deferred("setup_audio")
	for child in get_children():
		if child is HostCommand:
			if not (child.tick in host_command_nodes):
				host_command_nodes[child.tick] = []
			host_command_nodes[child.tick].append(child)
	update_property_list()
	.init()

func get_host_command(command_name):
	for command in host_command_nodes.values() + host_commands.values():
		if command is Array:
			for c in command:
				if c is Dictionary:
					if command_name in c:
						return c
				elif c is HostCommand:
					if command_name == c.command:
						return c
		if command is Dictionary:
			if command_name in command:
				return command

func update_property_list():
	if !host.is_ghost:
		property_list = Utils.get_copiable_properties(self)
		for hitbox in all_hitbox_nodes:
			hitbox.update_property_list()

func play_enter_sfx():
	enter_sfx_player.play()

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
	all_hitbox_nodes = []
	for child in get_children():
		if child is Hitbox:
			if child is ThrowBox:
				is_grab = true
			all_hitbox_nodes.append(child)
			host.hitboxes.append(child)
			child.native = native
			if child.guard_break:
				is_guard_break = true
	var earliest = 999999999
	for hitbox in all_hitbox_nodes:
		hitbox.host = host
		hitbox.init()
		var detect = hitbox.hitbox_type == Hitbox.HitboxType.Detect
		if !detect:
			has_hitboxes = true
		if !host.is_ghost:
			hitbox.property_list = get_script().get_property_list()
		if hitbox.start_tick > 0:
			if hitbox_start_frames.has(hitbox.start_tick):
				hitbox_start_frames[hitbox.start_tick].append(hitbox)
			else:
				hitbox_start_frames[hitbox.start_tick] = [hitbox]
			if !detect:
				if hitbox.start_tick < earliest:
					earliest = hitbox.start_tick
					earliest_hitbox_node = hitbox
		hitbox.connect("hit_something", self, "__on_hit_something")
		hitbox.connect("got_parried", self, "__on_got_parried")
		for hitbox2 in all_hitbox_nodes:
			if hitbox2.group == hitbox.group:
				hitbox.grouped_hitboxes.append(hitbox2)
	if earliest_hitbox <= 0 and earliest != 999999999:
		earliest_hitbox = earliest
		

func setup_hurtboxes():
	hurtbox_state_change_frames.clear()
	limb_hurtboxes.clear()
	for child in get_children():
		if child is HurtboxState:
			hurtbox_state_change_frames[child.start_tick] = child
		if child is LimbHurtbox:
			limb_hurtboxes.append(child)

func __on_hit_something(obj, hitbox):
	if active:
		_on_hit_something(obj, hitbox)
		host._on_hit_something(obj, hitbox)

func on_got_perfect_parried():
	pass

func on_got_blocked():
	pass

func on_got_blocked_by(who):
	pass

func on_got_perfect_parried_by(who):
	pass

func __on_got_parried():
	if active:
		_got_parried()

func _got_parried():
	pass

func detect(obj):
	pass

func spawn_particle_relative(scene: PackedScene, pos=Vector2(), dir=Vector2.RIGHT):
	var p = host.get_pos_visual()
	return host.spawn_particle_effect(scene, p + pos, dir)

func _enter_shared():
	same_as_last_state = false
	var prev = _previous_state()
	if prev:
		if force_same_direction_as_previous_state:
			host.set_facing(prev.last_facing)
		if prev != self:
			exit_tick = -1
		else:
			same_as_last_state = true
	if reset_momentum:
		host.reset_momentum()
	if reset_x_momentum:
		var vel = host.get_vel()
		host.set_vel("0", vel.y)
	if reset_y_momentum:
		var vel = host.get_vel()
		host.set_vel(vel.x, "0")

	current_tick = -1
	current_real_tick = -1
	start_tick = host.current_tick
	if enter_sfx_player and !ReplayManager.resimulating:
		play_enter_sfx()
	emit_signal("state_started")

func _exit_shared():
	exit_tick = current_tick + exit_tick
	if current_hurtbox:
		current_hurtbox.end(host)
	last_facing = host.get_facing_int()
	host.reset_hurtbox()
	host.end_invulnerability()
	host.end_projectile_invulnerability()
	host.end_throw_invulnerability()

	host.end_aerial_attack_invulnerability()
	host.end_grounded_attack_invulnerability()
	for child in get_children():
		if child is LimbHurtbox:
			child.active = false

	if disable_at_end:
		host.disable()

func xy_to_dir(x, y, mul="1.0", div="100.0"):
	return host.xy_to_dir(x, y, mul, div)

func update_sprite_frame():
#	if ReplayManager.resimulating:
#		return
	if !host.sprite.frames.has_animation(anim_name):
		return
	if host.sprite.animation != anim_name:
		host.sprite.animation = anim_name
		host.sprite.frame = 0
	var sprite_tick = current_tick / ticks_per_frame
#	var frame = host.fixed.int_map((current_tick % sprite_anim_length) if loop_animation else Utils.int_min(current_tick, sprite_anim_length), 0, sprite_anim_length, 0, host.sprite.frames.get_frame_count(host.sprite.animation))
	if loop_animation and absolute_loop:
		sprite_tick = host.current_tick / ticks_per_frame
	elif loop_animation and !refresh_loop:
		if same_as_last_state:
			sprite_tick = (current_tick + exit_tick) / ticks_per_frame
#			print(str(sprite_tick) + "  " + str(exit_tick))
		
	var frame = (sprite_tick % (sprite_anim_length - animation_loop_start) + animation_loop_start) if (loop_animation and sprite_tick > animation_loop_start) else Utils.int_min(sprite_tick, sprite_anim_length)
	host.sprite.frame = frame
