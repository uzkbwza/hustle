extends CharacterState

func _ready():
	pass

func _frame_44():
	host.gain_super_meter(host.MAX_SUPER_METER)
	host.unlock_achievement("ACH_HUSTLE", true)
	if !started_during_combo and host.combo_count <= 0:
		host.opponent.add_penalty(60, true)
