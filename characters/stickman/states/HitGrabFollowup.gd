extends ThrowState

func _frame_0():
	host.play_sound("Swish")
	pass

func _frame_6():
	host.play_sound("Swish")
	pass

func _on_hit_something(obj, hitbox):
	if obj == host.opponent:
		if host.combo_moves_used.has("HitGrab") and host.combo_moves_used["HitGrab"] <= 1:
			host.skull_shaker_bleed_ticks = host.SKULL_SHAKER_BLEED_TICKS
