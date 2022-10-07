extends CharacterState

class_name ParryState

const LANDING_LAG = 20

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

func _frame_13():
	parry_active = false

func can_parry_hitbox(hitbox: Hitbox):
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
		if host.is_grounded():
			queue_state_change("Landing", LANDING_LAG)
	host.apply_forces()
