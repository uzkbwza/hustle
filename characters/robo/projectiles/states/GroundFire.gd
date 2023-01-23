extends ObjectState

const FIRE_TIME = 120
const WIDTH = 100
const DAMAGE = 2

func _tick():
	if Utils.int_abs(host.obj_local_pos(host.creator.opponent).x) < WIDTH:
		if !host.creator.opponent.invulnerable and host.creator.opponent.is_grounded():
			host.creator.opponent.take_damage(DAMAGE)
	if current_tick > FIRE_TIME:
		host.disable()
	if current_tick % 20 == 0:
		host.play_sound("Fire")
