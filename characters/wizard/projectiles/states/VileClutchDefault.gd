extends DefaultFireball

export var screenshake_amount = 3
export var screenshake_ticks = 15
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _frame_10():
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, screenshake_amount, screenshake_ticks / 60.0)
