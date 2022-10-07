extends CharacterHurtState

const GROUND_FRIC = "0.05"

var hitstun = 0
var can_act = false

func _enter():
	can_act = false
	var hitbox = data["hitbox"]
	match hitbox.hit_height:
		Hitbox.HitHeight.High:
			anim_name = "HurtGroundedHigh"
		Hitbox.HitHeight.Mid:
			anim_name = "HurtGroundedMid"
		Hitbox.HitHeight.Low:
			anim_name = "HurtGroundedLow"
	
	hitstun = hitbox.hitstun_ticks
	var x = fixed_math.mul(hitbox.dir_x, "-1" if hitbox.facing == "Left" else "1")
	var force = fixed_math.normalized_vec_times(x, "0", hitbox.knockback)
	host.apply_force(force.x, force.y)


func _tick():
	host.apply_full_fric(GROUND_FRIC)
	host.apply_forces_no_limit()
	if current_tick >= hitstun:
		if can_act:
			return fallback_state
		else:
			enable_interrupt()
			can_act = true
