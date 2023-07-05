extends CharacterState

class_name SuperMove

export var _c_Super = 0
export var super_level = 1
export var supers_used = -1
export var super_freeze_ticks = 15
export var super_effect = true
export var scale_combo_meter = true

func is_usable():
	return .is_usable() and host.supers_available >= super_level

func _frame_0_shared():
	if scale_combo_meter and (super_level if supers_used == -1 else supers_used) > 0:
		host.combo_supers += 1
	if super_effect:
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
