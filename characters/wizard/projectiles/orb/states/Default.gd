extends ObjectState

export var LIFETIME = 3000

func _tick():
	if !host.locked:
		host.travel_towards_creator()
	host.attempt_triggered_attack()
	if current_tick > LIFETIME:
		host.disable()
