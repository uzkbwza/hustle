extends BeastState

const IS_FAST_SWIPE = true

func _enter():
	if data.y == -1:
		return "SwipeUp"
	elif data.y == 1:
		return "SwipeDown"
