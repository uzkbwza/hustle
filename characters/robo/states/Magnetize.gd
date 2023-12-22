extends RobotState

func _frame_0():
#	host.start_magnet_fx()
	host.start_magnetizing()
#	host.magnet_installed = true
#	host.start_hustle_fx()
#	host.armor_pips += 1
#	if host.armor_pips > host.MAX_ARMOR_PIPS:
#			host.armor_pips = host.MAX_ARMOR_PIPS

func is_usable():
	return host.magnet_ticks_left <= 0 and .is_usable() and host.grenade_object != null
