extends CharacterState

class_name ParryState

const LANDING_LAG = 8

export var particle_location = Vector2(14, -31)

enum ParryHeight {
	High,
	Low,
	Both,
}

var parry_active = false

export(ParryHeight) var parry_type = ParryHeight.High

func _enter():
	parry_active = true
	interruptible_on_opponent_turn = false
#
#func _frame_1():
#	parry_active = true
#	interruptible_on_opponent_turn = false


func _frame_10():
	parry_active = false

func parry():
	interruptible_on_opponent_turn = true

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
	if current_tick >= 10:
		parry_active = false
