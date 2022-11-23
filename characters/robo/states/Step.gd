extends RobotState

const MOVE_AMOUNT = 10
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _frame_6():
	self_interruptable = false
	host.move_directly_relative(MOVE_AMOUNT, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _frame_8():
	host.play_sound("Step")

func _frame_9():
	self_interruptable = true
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, 10, 6 / 60.0)
