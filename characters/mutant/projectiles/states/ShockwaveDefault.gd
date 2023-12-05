extends DefaultFireball


func _tick():
	._tick()
	if host.get_fighter().opponent.combo_count > 0:
		return "FizzleOut"
