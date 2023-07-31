extends "res://characters/states/Taunt.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _frame_7():
	host.play_sound("Swish")

func _frame_25():
	host.play_sound("Swish")
