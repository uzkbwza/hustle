extends CharacterState

const MAX_EXTRA_LAG_FRAMES = 5
const MIN_IASA = 7
const MIN_NEUTRAL_IASA = 9
const SUPER_IASA = 14

export var startup_invuln = true
export var grounded = false
var starting_y = 0
export var super = false

func _enter():
	if host.reverse_state:
		beats_backdash = false
	else:
		backdash_iasa = true
		beats_backdash = true
		backdash_iasa = false

func _frame_0():
	var min_iasa = (MIN_IASA if host.combo_count > 0 else MIN_NEUTRAL_IASA) if !super else SUPER_IASA
	starting_iasa_at = min_iasa
	iasa_at = min_iasa
	starting_y = host.get_pos().y
	host.move_directly(0, -1)
	host.set_grounded(false)
	if startup_invuln and host.initiative:
		host.start_projectile_invulnerability()

func _frame_4():
	host.end_projectile_invulnerability()

func _tick():
	if host.is_grounded():
		if host.combo_count > 0:
			queue_state_change("Landing", 4)
		else:
#			var lag = 7 if starting_y > -10 else 4
			var lag = 4 + Utils.int_max(MAX_EXTRA_LAG_FRAMES - current_tick, 0)
#			print(lag)
			queue_state_change("Landing", lag)
			var vel = host.get_vel()
	if super:
		host.move_directly_relative(5, 0)
