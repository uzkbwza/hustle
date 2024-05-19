extends CharacterState

var left_ground = false
var started_on_ground = false
var had_invuln = false

onready var hitbox = $Hitbox

func _frame_0():
	left_ground = false
	started_on_ground = host.is_grounded()
	
func _frame_1():
	had_invuln = false
	if host.initiative:
		host.start_projectile_invulnerability()
		had_invuln = true
	
func _frame_7():
	if !started_in_air:
		left_ground = true

func _tick():
	if current_tick <= 6:
		left_ground = false
	else:
		if started_in_air:
			if host.is_grounded():
				if current_tick < 15:
					host.set_vel(host.get_vel().x, "0")
					var force = fixed.normalized_vec_times("1.1", "-0.25", "11.0")
					host.apply_force_relative(force.x,  force.y)
				else:
					left_ground = true

	if current_tick >= 24:
		host.end_projectile_invulnerability()

	hitbox.block_cancel_allowed = !started_on_ground and !host.opponent.is_grounded()
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	if left_ground and host.is_grounded():
		queue_state_change("JumpKickLanding", 8)
