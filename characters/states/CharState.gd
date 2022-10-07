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

export var _c_Air_Data = 0
export(AirType) var air_type = AirType.Grounded
export var uses_air_movement = false

export var _c_Interrupt_Data = 0
export var iasa_at = -1
export var interrupt_frames = []


export var _c_Interrupt_Categories = 0
export(BusyInterrupt) var busy_interrupt_type = BusyInterrupt.Normal
export var burst_cancellable = true
export(String, MULTILINE) var interrupt_from_string
export(String, MULTILINE) var interrupt_into_string
export(String, MULTILINE) var hit_cancel_into_string

var interrupt_into = []
var interrupt_from = []
var hit_cancel_into = []
var busy_interrupt_into = []

func init():
	connect("state_interruptable", host, "on_state_interruptable", [self])
	connect("state_hit_cancellable", host, "on_state_hit_cancellable", [self])
	interrupt_into.append_array(get_cancel_categories(interrupt_into_string))
	interrupt_from.append_array(get_cancel_categories(interrupt_from_string))
	hit_cancel_into.append_array(get_cancel_categories(hit_cancel_into_string))
	if burst_cancellable:
		hit_cancel_into.append("OffensiveBurst")
	hit_cancel_into.append("InstantCancel")
	if title == "":
		title = state_name
	match busy_interrupt_type:
		BusyInterrupt.Normal:
			busy_interrupt_into.append("BusyNormal")
		BusyInterrupt.Hurt:
			busy_interrupt_into.append("BusyHurt")
	
	if iasa_at < 0:
		iasa_at = anim_length + iasa_at
	.init()

func get_ui_category():
	return ActionType.keys()[type]

func is_usable():
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

func get_cancel_categories(string: String):
	var categories = []
	for s in string.split("\n"):
		var category = s.strip_edges()
		if category:
			categories.append(category)
	return categories

func _enter_shared():
	._enter_shared()
	if uses_air_movement:
		host.air_movements_left -= 1
	call_deferred("update_sprite_frame")
	if has_hitboxes:
		host.gain_super_meter(WHIFF_SUPER_GAIN)


func enable_interrupt():
	emit_signal("state_interruptable")
	
func enable_hit_cancel():
	emit_signal("state_hit_cancellable")

func _on_hit_something(obj, hitbox):
	if hitbox.cancellable:
		enable_hit_cancel()

func _tick_shared():
	._tick_shared()
	if current_tick <= anim_length and !endless:
		if can_interrupt():
			enable_interrupt()

func can_interrupt():
	return current_tick == iasa_at or current_tick in interrupt_frames or current_tick == anim_length - 1

func _exit_shared():
	terminate_hitboxes()
	host.end_invulnerability()
	host.colliding_with_opponent = true
	host.state_interruptable = false
	host.state_hit_cancellable = false
	host.update_facing()
	emit_signal("state_ended")
