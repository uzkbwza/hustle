extends PlayerInfo
#
#func _process(delta):
#	$"%ArmorTexture".visible = fighter.armor_pips > 0
#
func set_fighter(fighter):
	.set_fighter(fighter)
	$HBoxContainer.alignment = BoxContainer.ALIGN_BEGIN if player_id == 1 else BoxContainer.ALIGN_END

func _process(delta):
	$"%LandingIndicator".visible = fighter.can_ground_pound
	if fighter.can_ground_pound:
		$"%LandingIndicator".modulate.a = 1.0 if Utils.pulse(0.3, 0.65) else 0.75
	pass
