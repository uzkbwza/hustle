extends BeastState

const IS_FAST_SWIPE = true

var lagged = false

func _enter():
	if data.y == -1:
		return "SwipeUp"
	elif data.y == 1:
		return "SwipeDown"
	lagged = false

func _tick():
	if current_tick == 1:
		if !host.initiative and !lagged:
			current_tick = 0
			lagged = true
