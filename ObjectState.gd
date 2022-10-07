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
var fixed_math

var anim_name

var has_hitboxes = false

var hitbox_start_frames = {
}

var active_hitboxes = []

func apply_enter_force():
	if enter_force_speed != "0.0":
		var force = xy_to_dir(enter_force_dir_x, enter_force_dir_y, enter_force_speed, "1.0")
#		force.y = host.fixed_math.mul(force.y, "2.0")
		host.apply_force_relative(force.x, force.y)

func _on_hit_something(_obj, _hitbox):
	pass

func clean_hitboxes():
	var invalid_hitboxes = []
	for hitbox in active_hitboxes:
		if !is_instance_valid(hitbox):
			invalid_hitboxes.append(hitbox)
	for hitbox in invalid_hitboxes:
		active_hitboxes.erase(hitbox)
func get_active_hitboxes():
	clean_hitboxes()
	return active_hitboxes

func _tick_shared():
	if current_tick < anim_length or endless:
		current_tick += 1
		update_sprite_frame()
		if hitbox_start_frames.has(current_tick + 1):
			for hitbox in hitbox_start_frames[current_tick + 1]:
				activate_hitbox(hitbox)
		var pos = host.get_pos()
		for hitbox in get_active_hitboxes():
			hitbox.facing = host.get_facing()
			hitbox.update_position(pos.x, pos.y)
			if hitbox.active:
				hitbox.tick()
			else:
				deactivate_hitbox(hitbox)
		
		if current_tick == force_tick:
			if force_speed != "0.0":
				var force = xy_to_dir(force_dir_x, force_dir_y, force_speed, "1.0")
		#		force.y = host.fixed_math.mul(force.y, "2.0")
				host.apply_force_relative(force.x, force.y)
		
		var method_name = "_frame_" + str(current_tick)
		# create methods called "_frame_1" or "_frame_27" etc to execute actions on those frames.
		if has_method(method_name):
			call(method_name)

func activate_hitbox(hitbox):
	hitbox.activate()
	active_hitboxes.append(hitbox)

func terminate_hitboxes():
	for hitbox in active_hitboxes:
		hitbox.deactivate()
	active_hitboxes.clear()

func deactivate_hitbox(hitbox):
	active_hitboxes.erase(hitbox)

func init():
	connect("state_started", host, "on_state_started", [self])
	connect("state_ended", host, "on_state_ended", [self])
	fixed_math = host.fixed_math
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
#	var frame = host.fixed_math.int_map((current_tick % sprite_anim_length) if loop_animation else Utils.int_min(current_tick, sprite_anim_length), 0, sprite_anim_length, 0, host.sprite.frames.get_frame_count(host.sprite.animation))
	var frame = (current_tick % sprite_anim_length) if loop_animation else Utils.int_min(current_tick, sprite_anim_length)
	host.sprite.frame = frame
