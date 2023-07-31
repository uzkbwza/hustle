extends PlayerInfo

onready var hover_bar = $"%HoverBar"

func set_fighter(fighter):
	.set_fighter(fighter)
	if player_id == 2:
		$"%HoverBar".fill_mode = TextureProgress.FILL_RIGHT_TO_LEFT
		$HBoxContainer.alignment = BoxContainer.ALIGN_END
		$"%HBoxContainer".alignment = BoxContainer.ALIGN_BEGIN
	
func _process(delta):
	if is_instance_valid(fighter):
		hover_bar.value = fighter.hover_left / float(fighter.HOVER_AMOUNT)
		hover_bar.self_modulate.a = 0.25 if fighter.hover_left <= fighter.HOVER_MIN_AMOUNT else 1.0
	#	hover_bar.modulate.b = 0.5 if fighter.hovering else 1.0
		hover_bar.tint_progress = Color("64d26b") if !fighter.hovering and !fighter.fast_falling else Color("ff333d")
#		$"%GeyserLabel".text = "geyser: " + str(fighter.geyser_charge)
		for i in range(3):
			var droplet = get_node("%" + str(i + 1))
			droplet.visible = i < fighter.geyser_charge
		$"%SparkSpeed".visible = fighter.spark_speed_frames > 0
		$"%SparkSpeed".modulate.a = 1.0 if Utils.pulse(0.2, 0.75) else 0.6

