extends StateInterface

class_name ObjectState

signal state_started()
signal state_ended()

export var fallback_state = "Wait"

export var _c_Animation_and_Length = 0
export var sprite_animation = ""
export var anim_length = 1
export var sprite_anim_length = -1
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

var current_tick = -1
var fixed

var anim_name

var has_hitboxes = false

var hitbox_start_frames = {
}

var frame_methods = []
var max_tick = 0

func apply_enter_force():
	if enter_force_speed != "0.0":
		var force = xy_to_dir(enter_force_dir_x, enter_force_dir_y, enter_force_speed, "1.0")
#		force.y = host.fixed.mul(force.y, "2.0")
		host.apply_force_relative(force.x, force.y)

func _on_hit_something(_obj, _hitbox):
	pass

func get_active_hitboxes():
	var hitboxes = []
	for start_frame in hitbox_start_frames:
		var items = hitbox_start_frames[start_frame]
		for item in items:
			if item is Hitbox:
				hitboxes.append(item)
	return hitboxes

func _tick_shared():
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
		
		if current_tick == force_tick:
			if force_speed != "0.0":
				var force = xy_to_dir(force_dir_x, force_dir_y, force_speed, "1.0")
		#		force.y = host.fixed.mul(force.y, "2.0")
				host.apply_force_relative(force.x, force.y)

		var new_max = false
		if current_tick > max_tick:
			max_tick = current_tick
			new_max = true
		
		if host.is_ghost or new_max or current_tick in frame_methods:
			var method_name = "_frame_" + str(current_tick)
			# create methods called "_frame_1" or "_frame_27" etc to execute actions on those frames.
			if has_method(method_name):
				call(method_name)
				frame_methods.append(current_tick)
			new_max = false

func _tick_after():
	for hitbox in get_active_hitboxes():
		var pos = host.get_pos()
		hitbox.update_position(pos.x, pos.y)

func copy_to(state: ObjectState):
	var properties = get_script().get_script_property_list()
	for variable in properties:
		var value = get(variable.name)
		if not (value is Object or value is Array or value is Dictionary):
			if value:
				state.set(variable.name, value)
		if data:
			if data is Dictionary or data is Array:
				state.data = data.duplicate()
			else:
				state.data = data
	pass

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

func setup_hitboxes():
	var hitboxes = []
	for child in get_children():
		if child is Hitbox:
			hitboxes.append(child)
			host.hitboxes.append(child)
	for hitbox in hitboxes:
		if hitbox is Hitbox:
			has_hitboxes = true
			hitbox.host = host
			if hitbox.start_tick >= 0:
				if hitbox_start_frames.has(hitbox.start_tick):
					hitbox_start_frames[hitbox.start_tick].append(hitbox)
				else:
					hitbox_start_frames[hitbox.start_tick] = [hitbox]
			hitbox.connect("hit_something", self, "__on_hit_something")
		for hitbox2 in hitboxes:
			if hitbox2.group == hitbox.group:
				hitbox.grouped_hitboxes.append(hitbox2)
func __on_hit_something(obj, hitbox):
	if active:
		_on_hit_something(obj, hitbox)

func _enter_shared():
	if reset_momentum:
		host.reset_momentum()
	apply_enter_force()
	current_tick = -1
	emit_signal("state_started")
	
func xy_to_dir(x, y, mul="1.0", div="100.0"):
	return host.xy_to_dir(x, y, mul, div)

func update_sprite_frame():
	if !host.sprite.frames.has_animation(anim_name):
		return
	if host.sprite.animation != anim_name:
		host.sprite.animation = anim_name
		host.sprite.frame = 0
#	var frame = host.fixed.int_map((current_tick % sprite_anim_length) if loop_animation else Utils.int_min(current_tick, sprite_anim_length), 0, sprite_anim_length, 0, host.sprite.frames.get_frame_count(host.sprite.animation))
	var frame = (current_tick % sprite_anim_length) if loop_animation else Utils.int_min(current_tick, sprite_anim_length)
	host.sprite.frame = frame
