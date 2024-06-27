extends "res://characters/states/OffensiveBurst.gd"

func is_usable():
	return .is_usable() and host.bc_charge
