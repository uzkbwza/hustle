extends DefaultFireball

const LIFETIME = 60

func _tick():
	if current_tick > LIFETIME:
		host.disable()
