extends BaseProjectile

func on_got_push_blocked():
	if creator:
		creator.on_got_push_blocked()
