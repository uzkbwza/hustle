extends RobotState

const VERTICAL_FORCE = "-10"
const MINIMUM_FORCE = "-5"
const HORIZ_FORCE = "5.0"
const X_FRIC = "0.015"
const GRAV = "0.6"
const FALL_SPEED = "16"
const SPIN_RATE = TAU / 8

func _frame_0():
	var amount = host.fixed_map("0.0", VERTICAL_FORCE, MINIMUM_FORCE, VERTICAL_FORCE, xy_to_dir(data.x, "0", VERTICAL_FORCE).x)
	host.apply_force_relative(HORIZ_FORCE, amount)
	host.move_directly(0, -1)
	host.set_grounded(false)
	host.sprite.hide()
	host.drive_jump_sprite.show()
	host.big_landing_effect()
	host.drive_jump_sprite.rotation = 0

func _tick():
	host.apply_x_fric(X_FRIC)
	host.apply_grav_custom(GRAV, FALL_SPEED)
	host.apply_forces_no_limit()
	if current_tick > 1 and host.is_grounded():
		return "Landing"
	if current_tick == 20:
		enable_interrupt()
	host.drive_jump_sprite.rotation += SPIN_RATE

func _exit():
	host.sprite.show()
	host.drive_jump_sprite.hide()
