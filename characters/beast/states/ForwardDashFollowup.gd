extends BeastState

func _enter():
	if data.x * host.get_facing_int() < 1:
		return "ForwardDashBackFollowup"
