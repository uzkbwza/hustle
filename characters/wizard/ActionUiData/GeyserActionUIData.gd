extends ActionUIData

func fighter_update():
	$Charge.max_value = max(fighter.geyser_charge, 1)
	$Charge.min_value = 1
#	$Charge.value = 1
	if fighter.geyser_charge < 2:
		$Charge.hide()
	else:
		$Charge.show()
	$Charge.update_values()
