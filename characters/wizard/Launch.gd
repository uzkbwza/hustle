extends WizardState

export var redirect = false

func _frame_0():
	var obj = host.obj_from_name(host.boulder_projectile)
	if obj:
		var dir = xy_to_dir(data.x, data.y)
		obj.launch(dir)
		host.play_sound("Telekinesis")

func is_usable():
	var obj = host.obj_from_name(host.boulder_projectile)
	if obj:
		if redirect and obj.current_state().state_name != "Launch":
			return false
		if !redirect and obj.current_state().state_name == "Launch":
			return false
	return host.boulder_projectile != null and .is_usable()
