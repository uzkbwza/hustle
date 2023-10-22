extends BeastState

func process_projectile(obj):
	host.shockwave_projectile = obj.obj_name

func _frame_4():
	host.play_sound("ShockwavePlunge")
	pass

func _frame_12():
	host.play_sound("ShockwaveRelease")
	host.play_sound("HitBass")
	host.screen_bump(Vector2(), 10, Utils.frames(7))

func is_usable():
	return host.shockwave_projectile == null and .is_usable()
