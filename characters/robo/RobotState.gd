extends CharacterState

class_name RobotState

func _frame_7():
	host.move_directly_relative(10, 0)

func _frame_9():
	host.play_sound("Step")
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, 10, 6 / 60.0)
