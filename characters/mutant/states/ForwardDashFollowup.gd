extends BeastState

func _enter():

	host.update_facing()
	if data and Utils.int_sign(data.x) != host.get_facing_int():
		return "ForwardDashBackFollowup"
