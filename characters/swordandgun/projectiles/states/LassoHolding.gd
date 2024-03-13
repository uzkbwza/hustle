extends ObjectState



func _tick():
	if host.get_fighter().current_state().state_name == "Wait":
		host.disable()
