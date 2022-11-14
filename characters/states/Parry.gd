extends CharacterState

class_name ParryState

const LANDING_LAG = 8
const AFTER_PARRY_ACTIVE_TICKS = 0

export var particle_location = Vector2(14, -31)

enum ParryHeight {
	High,
	Low,
	Both,
}

export(ParryHeight) var parry_type = ParryHeight.High

var initial_parry_type
var parry_tick = 0
var parried = false

func _ready():
	initial_parry_type = parry_type

var parry_active = false


func _frame_0():
	parry_type = initial_parry_type
	parry_active = true
	parry_tick = 0
	parried = false
	interruptible_on_opponent_turn = false
#
#func _frame_1():
#	parry_active = true
#	interruptible_on_opponent_turn = false

func is_usable():
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel"

func _frame_10():
	if !parried:
		parry_active = false

func parry():
	interruptible_on_opponent_turn = true
	enable_interrupt()
	host.parried = true
#	parry_type = ParryHeight.Both
#	parry_tick = current_tick

func can_parry_hitbox(hitbox):
	if hitbox == null:
		return false
	if !active:
		return false
	if !parry_active:
		return false
	match hitbox.hit_height:
		Hitbox.HitHeight.High:
			return parry_type == ParryHeight.High or parry_type == ParryHeight.Both
		Hitbox.HitHeight.Mid:
			return parry_type == ParryHeight.High or parry_type == ParryHeight.Both
		Hitbox.HitHeight.Low:
			return parry_type == ParryHeight.Low or parry_type == ParryHeight.Both
	return false

func _tick():
	host.apply_fric()
	if air_type == AirType.Aerial:
		host.apply_grav()
		if !parry_active and host.is_grounded():
			queue_state_change("Landing", LANDING_LAG)
	host.apply_forces()
#	if !parried:
	if current_tick >= 10:
		parry_active = false
#	if parried:
#		if current_tick >= parry_tick + AFTER_PARRY_ACTIVE_TICKS:
#			parry_active = false
