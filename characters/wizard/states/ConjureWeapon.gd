extends WizardState

func _frame_0():
	host.has_hyper_armor = true
	interruptible_on_opponent_turn = false

func on_got_hit():
	interruptible_on_opponent_turn = true
