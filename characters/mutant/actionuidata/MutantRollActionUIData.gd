extends ActionUIData

func fighter_update():
	$Direction.S = !fighter.is_grounded()
	if $Direction.pressed_button.name == "S":
		$Direction.set_sensible_default("W" if fighter.get_facing_int() == -1 else "E")
