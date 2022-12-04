extends CharacterState


func _tick():
	if current_tick == 3:
		self_hit_cancellable = host.initiative
		if host.initiative:
			current_tick = 5
