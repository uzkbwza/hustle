extends RobotState

const SPEED_LIMIT = "20"

const STALL = 6

export var SPEED = "3.0"

export var dir = 1

onready var hitbox = $"../DriveForward/Hitbox"

var stall = 0

func _enter():
	if state_name == "DriveForward" and _previous_state_name() == "DriveBackward":
		stall = STALL
		host.reset_momentum()

func _tick():
	if stall > 0:
		stall -= 1
		current_tick = 0

	if stall <= 0:
		if dir != 0:
			host.apply_force_relative(fixed.mul(SPEED, str(dir)), "0")
			if current_tick % 12 == 0:
				host.play_sound("DriveMove")
		else:
			if current_tick % 12 == 0:
				host.play_sound("DriveIdle")
	host.apply_forces_no_limit()
	host.limit_speed(SPEED_LIMIT)

func _frame_0():
	if dir == 1:
		host.has_projectile_armor = true
#	next_state_on_hold = !host.drive_cancel
#	next_state_on_hold_on_opponent_turn = !host.drive_cancel

func _frame_1():
	if dir == 1:
		if host.drive_cancel:
			hitbox.cancellable = false
			fallback_state = "UnDriveCancel"
			anim_length = 20
		else:
			fallback_state = "DriveIdle"
			hitbox.cancellable = true
			anim_length = 12

func _frame_5():
	host.has_projectile_armor = false

func on_got_perfect_parried():
	interruptible_on_opponent_turn = false
	host.hitlag_ticks += 3
	pass
