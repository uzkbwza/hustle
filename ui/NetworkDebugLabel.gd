extends Label

func _process(_delta):
	text = str(Network.action_inputs) + "\n" + str(Network.turns_ready)
