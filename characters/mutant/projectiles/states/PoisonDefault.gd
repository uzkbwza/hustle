extends ObjectState

const DAMAGE_EVERY = 15

const DAMAGE = 5

func _enter():
	host.poison_particle.start()

func _tick():
	var opponent = host.get_fighter().opponent
	var pos = opponent.get_hurtbox_center()
	host.set_pos(pos.x, pos.y)
	if current_tick % DAMAGE_EVERY == 0:
		opponent.take_damage(DAMAGE)

	if host.is_ghost:
		host.poison_particle_2.hide()

func _frame_600():
	host.disable()
