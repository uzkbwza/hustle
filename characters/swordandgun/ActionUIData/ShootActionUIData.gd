extends ActionUIData

func fighter_update():
	$Shots.max_value = fighter.bullets_left
	$Shots.update_values()
