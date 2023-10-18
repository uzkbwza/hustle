extends "res://characters/stickman/states/NunChuk.gd"

const PROJECTILE = preload("res://characters/stickman/projectiles/HeavyWhipWave.tscn")

var charged = false

func _enter():
	determine_charge()
	if data is Dictionary:
		if data.y != 0:
			return "NunChukLightHigh"
	determine_charge()

func determine_charge():
	if "NunChukHeavy" in _previous_state_name() and (state_name == "NunChukLight" or state_name == "NunChukLightHigh"):
		charged = true
	elif (_previous_state_name() == "NunChukLight" or _previous_state_name() == "NunChukLightHigh") and _previous_state().charged:
		charged = true
	else:
		charged = false

func _frame_4():
	if charged:
		spawn_exported_projectile()
	pass

func _ready():
	pass
