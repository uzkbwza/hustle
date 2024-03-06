extends "res://characters/states/Taunt.gd"

export var charge = false

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _frame_1():
	if charge:
		current_tick = 28
		host.add_juke_pips(host.JUKE_PIPS_PER_USE*3)
		host.play_sound("Howl")
		host.play_sound("Howl2")
#		host.play_sound("HitBass")
		host.can_air_dash = true

func _frame_7():
	host.play_sound("Swish")

func _frame_24():
	host.add_juke_pips(host.JUKE_PIPS_PER_USE)

func _frame_25():
	host.play_sound("Swish")
	

func _frame_26():
	host.play_sound("Howl")
	host.play_sound("Howl2")
#	host.play_sound("HitBass")
	
func _frame_34():
	host.add_juke_pips(host.JUKE_PIPS_PER_USE)
	
func _frame_44():
	if !charge:
		host.add_juke_pips(host.JUKE_PIPS_PER_USE)
		._frame_44()

func is_usable():
	return .is_usable()
