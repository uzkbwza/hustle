extends CharacterState

const DEFAULT_LAG = 4
const MAX_EXTRA_LAG_FRAMES = 5

var lag = 0

func set_lag(lag=null):
	if lag == null:
		lag = DEFAULT_LAG
	if data is int:
		lag = data
	if _previous_state() and host.combo_count <= 0 and host.opponent.combo_count <= 0:
		lag = lag + Utils.int_max(MAX_EXTRA_LAG_FRAMES - _previous_state().current_tick, 0)
#		lag = lag + Utils.int_max(MAX_EXTRA_LAG_FRAMES - host.turn_frames, 0)
	anim_length = lag
	iasa_at = lag - 1
	self.lag = lag

func _frame_0():
	set_lag(null)

func _tick():
	if current_tick > 4:
		host.apply_fric()
	host.apply_forces()
	interruptible_on_opponent_turn = host.opponent.combo_count <= 0 and lag <= DEFAULT_LAG
