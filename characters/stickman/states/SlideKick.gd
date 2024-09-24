extends CharacterState

const X_FRIC = "0.06"
const SPEED_LIMIT = "22"

var hit = false

func _enter():
	hit = false

func _frame_2():
	if host.initiative:
		host.start_projectile_invulnerability()
	if host.reverse_state and host.combo_count <= 0:
		host.add_penalty(25)

func _tick():
	host.apply_forces_no_limit()
	host.apply_x_fric(X_FRIC)
	host.limit_speed(SPEED_LIMIT)
	if current_tick > 24 and !hit and host.is_grounded():
		return "Knockdown"

func _frame_13():
	host.end_projectile_invulnerability()

func _frame_16():
	if hit:
		enable_interrupt()
#		queue_state_change("Wait")

func on_got_blocked():
	.on_got_blocked()
	hit = true

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	hit = true
