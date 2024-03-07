extends PlayerInfo

const LOIC_READY_BAR = preload("res://characters/robo/loic_meter_progress2.png")
const LOIC_CHARGING_BAR = preload("res://characters/robo/loic_meter_progress1.png")


func set_fighter(fighter):
	.set_fighter(fighter)
	$"%HBoxContainer".alignment = BoxContainer.ALIGN_BEGIN if player_id == 1 else BoxContainer.ALIGN_END
	if player_id == 2:
		$"%HBoxContainer".move_child($"%LOICMeterContainer", 0)
		$"%HBoxContainer".move_child($"%ArmorIndicatorContainer", 0)
		$"%LOICMeter".fill_mode = TextureProgress.FILL_RIGHT_TO_LEFT

func _process(delta):
	if !is_instance_valid(fighter):
		return
	$"%LandingIndicator".modulate.a = 0.15
	if fighter.can_ground_pound:
		$"%LandingIndicator".modulate.a = 1.0 if Utils.pulse(0.3, 0.65) else 0.75
	$"%ArmorIndicator".modulate = Color("d440b6") if fighter.super_armor_installed else Color.white
	$"%ArmorIndicator".modulate.a = 0.15
	if fighter.armor_pips > 0:
		$"%ArmorIndicator".modulate.a = 1.0 if Utils.pulse(0.3, 0.65) else 0.75
	$"%LOICMeter".texture_progress = LOIC_READY_BAR if fighter.can_loic else LOIC_CHARGING_BAR
	$"%LOICMeter".value = (fighter.loic_meter / float(fighter.LOIC_METER)) * $"%LOICMeter".max_value
