extends WizardState

func _frame_13():
	host.add_geyser_charge()

func _enter():
	host.start_moisture_effect()
	
func _exit():
	host.stop_moisture_effect()

func is_usable():
	return .is_usable() and host.geyser_charge < 3
