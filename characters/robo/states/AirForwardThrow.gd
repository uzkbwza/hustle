extends ThrowState

func _enter():
	air_ground_bounce = host.combo_count != 0
