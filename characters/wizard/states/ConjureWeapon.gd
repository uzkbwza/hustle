extends WizardState

var got_hit

func _frame_0():
	host.has_hyper_armor = true
	got_hit = false

func on_got_hit():
	got_hit = true
	pass

func _tick():
	if got_hit:
		enable_interrupt()
		got_hit = false
