extends RobotState

func _frame_0():
#	host.start_magnet_fx()
	host.start_magnetizing()
#	host.magnet_installed = true
#	host.start_hustle_fx()
#	host.armor_pips += 1
#	if host.armor_pips > host.MAX_ARMOR_PIPS:
#			host.armor_pips = host.MAX_ARMOR_PIPS

func _tick():
	if current_tick == 7 and host.combo_count > 0:
		enable_interrupt()

func is_usable():
	return .is_usable() and (host.magnet_ticks_left <= 0 and host.grenade_object != null)
