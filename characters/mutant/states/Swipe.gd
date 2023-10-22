extends BeastState

func _enter():
	if data.y == -1:
		return "SwipeUp"
	elif data.y == 1:
		return "SwipeDown"
