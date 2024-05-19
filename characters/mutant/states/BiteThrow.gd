extends ThrowState

func _frame_0():
	host.opponent.z_index = -2
	if host.combo_proration < 3:
		host.combo_proration = 3
 
