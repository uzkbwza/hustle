extends CharacterState

var can_apply_sadness = false

func _enter():
	can_apply_sadness = host.combo_count <= 0

func _frame_44():
	host.gain_super_meter(host.MAX_SUPER_METER)
	host.unlock_achievement("ACH_HUSTLE", true)
	if can_apply_sadness and host.combo_count <= 0:
		if host.opponent.current_state().state_name != "Taunt":
			host.opponent.add_penalty(40, true)

func _tick():
	if can_apply_sadness and host.combo_count <= 0 and current_tick % 4 == 0 and host.is_grounded():
		host.opponent.add_penalty(1)
