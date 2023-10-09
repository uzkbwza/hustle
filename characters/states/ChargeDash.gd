extends CharacterState

func _frame_6():
	if fallback_state == "ChargeDashForward":
		queue_state_change(fallback_state, {"x": 100, "charged": true})
	else:
		queue_state_change(fallback_state)
