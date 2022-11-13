extends "res://characters/states/InstantCancel.gd"

func is_usable():
	return .is_usable() and !host.got_parried
