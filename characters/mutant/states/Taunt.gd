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

func _frame_26():
	host.play_sound("Howl")
	host.play_sound("Howl2")

	host.play_sound("HitBass")
	
func _frame_44():
	._frame_44()
	host.add_juke_pips(host.JUKE_PIPS_PER_USE)
