extends CharacterState

const X_FRIC = "0.15"

func _tick():
	host.apply_forces_no_limit()
	host.apply_x_fric(X_FRIC)
