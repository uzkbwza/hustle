extends BeastState

const JUMP_FORCE = -10
const JUMP_HORIZ_SPEED = "7.0"
const FIGHTER_JUMP_FORCE = -5
const BASE_JUMP_FORCE = -5

var jumped = false

func _enter():
	jumped = false

func _frame_5():
	host.start_projectile_invulnerability()

func _frame_16():
	host.end_projectile_invulnerability()

func detect(obj):
	if jumped:
		return
	jumped = true
	host.set_vel(0, 0)
	var dir = xy_to_dir(data.x, data.y)
	var dir_x = fixed.mul(dir.x, JUMP_HORIZ_SPEED)
	var dir_y = fixed.mul(dir.y, str(JUMP_FORCE if !obj.is_in_group("Fighter") else FIGHTER_JUMP_FORCE))
	dir_y = fixed.mul(dir_y, "-1")
	host.apply_force(dir_x, dir_y)
	host.apply_force(0, BASE_JUMP_FORCE)
	queue_state_change("ProjectileGrabJump")
	if !obj.is_in_group("Fighter"):
		obj.apply_force(0, -JUMP_FORCE)
		pass
