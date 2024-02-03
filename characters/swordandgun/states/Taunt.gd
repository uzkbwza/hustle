extends "res://characters/states/Taunt.gd"

export var guntrick = false


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _frame_15():
	if state_name == "Guntrick":
		current_tick += 2

func _frame_7():
	host.play_sound("Block")

func is_usable():
	return .is_usable() and !(guntrick and !host.opponent.busy_interrupt)
