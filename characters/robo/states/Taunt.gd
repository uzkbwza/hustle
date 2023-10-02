extends "res://characters/states/Taunt.gd"

func _enter():
	can_apply_sadness = host.combo_count <= 0
	host.start_hustle_fx()
	next_state_on_hold = false
	next_state_on_hold_on_opponent_turn = false
	anim_length = 45
	if !host.is_grounded():
		anim_length = 11
		next_state_on_hold = true
		next_state_on_hold_on_opponent_turn = true


func _exit():
	host.stop_hustle_fx()
