extends RobotState


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _tick():
	if current_tick < 12 and current_tick > 4:
		host.set_vel(fixed.mul("5", str(host.get_facing_int())), "0")
