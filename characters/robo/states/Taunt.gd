extends "res://characters/states/Taunt.gd"

func _enter():
	host.start_hustle_fx()

func _exit():
	host.stop_hustle_fx()
