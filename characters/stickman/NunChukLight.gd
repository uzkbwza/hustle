extends "res://characters/stickman/states/NunChuk.gd"

func _enter():
	if data:
		if data.y != 0:
			return "NunChukLightHigh"

func _ready():
	pass
