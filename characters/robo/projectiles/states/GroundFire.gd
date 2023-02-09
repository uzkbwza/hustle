extends ObjectState

const FIRE_TIME = 120
const DAMAGE = 2
export var width = 100

func _tick():
	var opponent = host.get_opponent()
	if opponent != null and Utils.int_abs(host.obj_local_pos(opponent).x) < width:
		if !opponent.invulnerable and opponent.is_grounded():
			opponent.take_damage(DAMAGE)
	if current_tick > FIRE_TIME:
		host.disable()
		if !host.from_loic and host.creator:
			host.creator.can_flamethrower = true
	if current_tick % 20 == 0:
		host.play_sound("Fire")
	host.set_y(0)
