extends CharacterState

class_name RobotState

export var is_super = false
export var super_level = 1
export var supers_used = -1
export var super_freeze_ticks = 15
export var super_effect = true
export var can_fly = true
export var throw_invuln_frames = 0

func is_usable():
	if !is_super:
		return .is_usable()
	return .is_usable() and host.supers_available >= super_level

func _enter_shared():
	._enter_shared()
	if !is_super:
		return
	if super_effect:
		host.start_super()
		host.play_sound("Super")
		host.play_sound("Super2")
		host.play_sound("Super3")
	for i in range(super_level if supers_used == -1 else supers_used):
		host.use_super_bar()

func _tick_shared():
	._tick_shared()
	if current_tick == throw_invuln_frames:
		host.end_throw_invulnerability()

func _frame_0_shared():
	if throw_invuln_frames > 0:
		host.start_throw_invulnerability()
