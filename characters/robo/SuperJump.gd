extends "res://characters/states/Jump.gd"

func _frame_7():
	._frame_7()
	host.has_projectile_armor = true
#
func _frame_8():
	host.air_movements_left = 3

func _frame_38():
	host.has_projectile_armor = false
