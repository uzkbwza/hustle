extends ObjectState

class_name CharacterState

signal state_interruptable()
signal state_hit_cancellable()

const WHIFF_SUPER_GAIN = 10

enum ActionType {
	Movement,
	Attack,
	Special,
	Super,
	Defense,
	Hurt,
}

enum BusyInterrupt {
	Normal,
	Hurt,
	None,
}

enum AirType {
	Grounded,
	Aerial,
	Both
}

export var _c_Menu = 0
export(String) var title
export var show_in_menu = true
export(ActionType) var type
export(PackedScene) var data_ui_scene = null
export(Texture) var button_texture = null
export var flip_icon = true

export var _c_Air_Data = 0
export(AirType) var air_type = AirType.Grounded
export var uses_air_movement = false
export var land_cancel = false

export var _c_Interrupt_Data = 0
export var iasa_at = -1
export var interrupt_frames = []
export var throw_techable = false
export var interruptible_on_opponent_turn = false


export var _c_Interrupt_Categories = 0
export(BusyInterrupt) var busy_interrupt_type = BusyInterrupt.Normal
export var burst_cancellable = true
export var burstable = true
export var self_hit_cancellable = true
export var self_interruptable = true
export var reversible = true
export var instant_cancellable = true
export var force_feintable = false
export var can_feint_if_possible = true

export(String, MULTILINE) var interrupt_from_string
export(String, MULTILINE) var interrupt_into_string
export(String, MULTILINE) var hit_cancel_into_string
export(String, MULTILINE) var interrupt_exceptions_string
export(String, MULTILINE) var hit_cancel_exceptions_string

export var _c_Stances = 0
export(String, MULTILINE) var allowed_stances_string = "Normal"
export(String) var change_stance_to = ""

export var _c_Misc = 0
export var release_opponent_on_startup = false
export var initiative_effect = false

var initiative_effect_spawned = false

var started_in_air = false
var hit_yet = false
var hit_cancelled = false

var feinting = false

var interrupt_into = []
var interrupt_from = []
var interrupt_exceptions = []
var hit_cancel_into = []
var hit_cancel_exceptions = []
var busy_interrupt_into = []
var allowed_stances = []

var is_hurt_state = false

func init():
	connect("state_interruptable", host, "on_state_interruptable", [self])
	connect("state_hit_cancellable", host, "on_state_hit_cancellable", [self])

	interrupt_into.append_array(get_categories(interrupt_into_string))
	interrupt_from.append_array(get_categories(interrupt_from_string))
	hit_cancel_into.append_array(get_categories(hit_cancel_into_string))
	hit_cancel_exceptions.append_array(get_categories(hit_cancel_exceptions_string))
	allowed_stances.append_array(get_categories(allowed_stances_string))
	interrupt_exceptions.append_array(get_categories(interrupt_exceptions_string))

	if burst_cancellable:
		hit_cancel_into.append("OffensiveBurst")
	if instant_cancellable:
		hit_cancel_into.append("InstantCancel")
	if title == "":
		title = state_name
	match busy_interrupt_type:
		BusyInterrupt.Normal:
			busy_interrupt_into.append("BusyNormal")
		BusyInterrupt.Hurt:
			if burstable:
				busy_interrupt_into.append("BusyHurt")
		BusyInterrupt.None:
			pass
	if iasa_at < 0:
		iasa_at = anim_length + iasa_at
	.init()

func get_ui_category():
	return ActionType.keys()[type]

func is_usable():
	if host.current_state().state_name == "WhiffInstantCancel" and !has_hitboxes:
		return false
	if air_type == AirType.Aerial:
		if host.is_grounded():
			return false
	if air_type == AirType.Grounded:
		if !host.is_grounded():
			return false
	if uses_air_movement:
		if host.air_movements_left <= 0:
			return false
	return true

func get_categories(string: String):
	return Utils.split_lines(string)

func _enter_shared():
	._enter_shared()
	
#	host.update_advantage()
#	if host.opponent:
#		host.opponent.update_advantage()
	hit_yet = false
	started_in_air = false
	host.update_grounded()
	if change_stance_to:
		host.change_stance_to(change_stance_to)
	if !host.is_grounded():
		started_in_air = true
	if uses_air_movement:
		if !host.infinite_resources and host.gravity_enabled:
			host.air_movements_left -= 1
	call_deferred("update_sprite_frame")
	if has_hitboxes:
		host.gain_super_meter(WHIFF_SUPER_GAIN)

func allowed_in_stance():
	return "All" in allowed_stances or host.stance in allowed_stances

func enable_interrupt():
#	host.update_advantage()
	emit_signal("state_interruptable")

func enable_hit_cancel():
	emit_signal("state_hit_cancellable")

func _on_hit_something(obj, hitbox):
	if !hit_yet and obj == host.opponent:
		hit_yet = true
		host.stack_move_in_combo(state_name)
	._on_hit_something(obj, hitbox)
	if hitbox.cancellable:
		enable_hit_cancel()

func process_hitboxes():
#	if hitbox_start_frames.has(current_tick + 1) and host.feinting:
#		host.feinting = false
#		feinting = true
#		return true
	.process_hitboxes()

#func process_feint():
#	return "WhiffInstantCancel"

func _tick_shared():
	if current_tick == 0:
		feinting = host.feinting
		hit_cancelled = false
#		hit_cancelled = false
		if initiative_effect and host.initiative:
			if host.initiative_effect:
				host.spawn_particle_effect(preload("res://fx/YomiEffect.tscn"), host.get_center_position_float())
			host.initiative_effect = false
			
		if release_opponent_on_startup:
			host.release_opponent()
		if !is_hurt_state and reversible:
			if host.reverse_state:
				var facing = host.get_facing_int()
				var opponent_x = host.opponent.get_pos().x
				var my_x = host.get_pos().x
				var equal_x = opponent_x == my_x
				host.set_facing(facing * (-1 if !equal_x else 1))
				host.update_data()
		else:
			host.reverse_state = false
#	if busy_interrupt_type != BusyInterrupt.Hurt:
#		host.update_advantage()
#		if host.opponent:
#			host.opponent.update_advantage()
	var next_state = ._tick_shared()
	if next_state:
		return next_state

	if land_cancel and host.is_grounded() and started_in_air and fixed.gt(host.get_vel().y, "0"):
		queue_state_change("Landing")
	if current_tick <= anim_length and !endless:
		if can_interrupt():
			enable_interrupt()

func _tick_after():
	host.set_lowest_tick(current_real_tick)
	._tick_after()

func can_feint():
	return (has_hitboxes or force_feintable) and host.feints > 0 and can_feint_if_possible

func can_interrupt():
	return current_tick == iasa_at or current_tick in interrupt_frames or current_tick == anim_length - 1

func _exit_shared():
	if feinting:
		host.feinting = false
	feinting = false
#	host.update_advantage()
#	host.opponent.update_advantage()
	._exit_shared()
	host.update_facing()
	terminate_hitboxes()
	host.end_invulnerability()
	host.end_projectile_invulnerability()
	host.got_parried = false
	host.colliding_with_opponent = true
	host.state_interruptable = false
	host.state_hit_cancellable = false
#	if host.reverse_state:
#		host.set_facing(host.get_facing_int() * -1)
#	host.sprite.rotation = 0
	emit_signal("state_ended")
	host.z_index = 0
