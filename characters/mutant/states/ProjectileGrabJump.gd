extends CharacterState

func _enter():
	host.play_sound("Bounce2")
	host.play_sound("HitBass")

func _frame_0():
	host.start_projectile_invulnerability()

func _frame_3():
	host.end_projectile_invulnerability()
