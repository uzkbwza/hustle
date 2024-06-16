extends BeastState
#
func _frame_0():
	host.colliding_with_opponent = false


func on_got_blocked():
	host.colliding_with_opponent = true
	host.reset_momentum()
#func _tick():
#	if current_tick < 3:
#		host.reset_momentum()

#func _frame_4():
#	host.has_hyper_armor = true
#
#func _frame_9():
#	host.has_hyper_armor = false
