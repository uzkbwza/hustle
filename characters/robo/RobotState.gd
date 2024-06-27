extends CharacterState

class_name RobotState

export var _c_Robot_Obsolete = 0
export var is_super = false
export var super_level = 1
export var supers_used = -1
export var super_freeze_ticks = 15
export var super_effect = true
export var can_fly = true
export var throw_invuln_frames = 0
export var super_scale_combo_meter = true

func is_usable(): 
	if !is_super:
		return .is_usable()
	return .is_usable() and host.supers_available >= super_level

func _enter_shared():
	._enter_shared()
	if throw_invuln_frames > 0:
		host.start_throw_invulnerability()

func _frame_0_shared():
	._frame_0_shared()
	if !is_super:
		return

	var levels = super_level if supers_used == -1 else supers_used
	if super_scale_combo_meter and levels > 0:
		host.combo_supers += 1
	if !force_super_effect and (super_effect and levels <= 1):
		host.ex_effect(super_freeze_ticks)
	elif force_super_effect or super_effect:
		host.super_effect(super_freeze_ticks)
	for i in range(super_level if supers_used == -1 else supers_used):
		host.use_super_bar()

func _tick_shared():
	._tick_shared()
	if current_tick == throw_invuln_frames and throw_invuln_frames > 0:
		host.end_throw_invulnerability()
