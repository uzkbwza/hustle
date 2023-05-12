extends BaseProjectile

export var from_loic = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func disable():
	.disable()
	var fighter = get_fighter()
	if fighter and fighter.flame_touching_opponent == obj_name:
		fighter.flame_touching_opponent = null
