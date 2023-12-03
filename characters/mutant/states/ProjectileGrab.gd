extends BeastState

const JUMP_FORCE = -15
const JUMP_HORIZ_SPEED = "7.0"
const FIGHTER_JUMP_FORCE = -10

var jumped = false

func _enter():
	jumped = false

func _frame_6():
	host.start_projectile_invulnerability()

func _frame_16():
	host.end_projectile_invulnerability()

func detect(obj):
	if jumped:
		return
	jumped = true
	host.apply_force(xy_to_dir(data.x, data.y, JUMP_HORIZ_SPEED).x, str(JUMP_FORCE if !obj.is_in_group("Fighter") else FIGHTER_JUMP_FORCE))
	host.set_vel(0, 0)
	queue_state_change("ProjectileGrabJump")
	if !obj.is_in_group("Fighter"):
		obj.apply_force(0, -JUMP_FORCE)
		pass
