extends CharacterState

class_name SuperMove

export var _c_Super_OBSOLETE = 0
export var super_level = 1
export var supers_used = -1
export var super_freeze_ticks = 15
export var super_effect = true
export var scale_combo_meter = true

func is_usable():
	return .is_usable() and host.supers_available >= super_level

func _frame_0_shared():
	var levels = super_level if supers_used == -1 else supers_used
	if scale_combo_meter and levels > 0:
		host.combo_supers += 1
	if !force_super_effect and (super_effect and levels <= 1):
		host.ex_effect(super_freeze_ticks)
	elif force_super_effect or super_effect:
		host.super_effect(super_freeze_ticks)
	for i in range(super_level if supers_used == -1 else supers_used):
		host.use_super_bar()

#func _enter_shared():
#	._enter_shared()
#	host.combo_supers += 1
#	if super_effect:
#		host.super_effect(super_freeze_ticks)
#	for i in range(super_level if supers_used == -1 else supers_used):
#		host.use_super_bar()
