extends WizardState

var got_hit = false

func _frame_0():
	got_hit = false

func _frame_6():
	if !got_hit:
		host.has_hyper_armor = true
	host.start_projectile_invulnerability()

func _frame_14():
	host.has_hyper_armor = false
	host.end_projectile_invulnerability()

func on_got_hit():
	got_hit = true
	feinting = false
	host.feinting = false

#func _tick():
#	if got_hit:
##		enable_interrupt()
#		got_hit = false
