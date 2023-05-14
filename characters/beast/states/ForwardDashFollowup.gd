extends BeastState

func _enter():
	if data.x < 1:
		return "ForwardDashBackFollowup"
