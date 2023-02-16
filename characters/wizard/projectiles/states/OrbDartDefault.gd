extends "res://projectile/DirProjectileDefault.gd"

onready var hitbox = $Hitbox

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _frame_0():
	._frame_0()
	var dir = data["dir"]
	hitbox.dir_x = fixed.mul(str(dir.x), str(host.get_facing_int()))
	hitbox.dir_y = str(dir.y)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
