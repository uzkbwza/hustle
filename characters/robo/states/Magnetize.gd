extends RobotState

func _frame_0():
	host.start_magnet_fx()
	host.start_magnetizing()
#	host.armor_pips += 1
#	if host.armor_pips > host.MAX_ARMOR_PIPS:
#			host.armor_pips = host.MAX_ARMOR_PIPS
