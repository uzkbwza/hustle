extends CharacterState

func _enter():
	throw_techable = true

func _frame_4():
	throw_techable = false

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
