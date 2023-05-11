extends WizardState

func _frame_0():
	var obj: TelekinesisProjectile = host.obj_from_name(host.boulder_projectile)
	if obj:
		var dir = xy_to_dir(data.x, data.y)
		obj.launch(dir)
		host.play_sound("Telekinesis")

func is_usable():
	return host.boulder_projectile != null and .is_usable()
