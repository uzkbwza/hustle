extends SuperMove

func _enter():
	pass

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
