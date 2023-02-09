extends DefaultFireball

const LIFETIME = 100

func _tick():
	if current_tick > LIFETIME:
		host.disable()
