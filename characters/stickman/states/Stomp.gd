extends CharacterState

func _tick():
	host.apply_fric()
	host.apply_forces()

func _frame_10():
	host.spawn_particle_effect(preload("res://characters/stickman/StompEffect.tscn"), host.get_pos_visual() + Vector2(36 * host.get_facing_int(), 0))
	pass
