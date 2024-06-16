extends PlayerInfo

onready var hover_bar = $"%HoverBar"
onready var flame_charge = $"%FlameCharge"
#const CHARGED_FLAME_SPRITE = preload("res://characters/wizard/sprites/flamewave_charge.png")
#const UNCHARGED_FLAME_SPRITE = preload("res://characters/wizard/sprites/flamewave_charge_empty.png")
func set_fighter(fighter):
	.set_fighter(fighter)
	if player_id == 2:
		$"%HoverBar".fill_mode = TextureProgress.FILL_RIGHT_TO_LEFT
		$HBoxContainer.alignment = BoxContainer.ALIGN_END
		$"%HBoxContainer".alignment = BoxContainer.ALIGN_BEGIN
		$"%HBoxContainer2".alignment = BoxContainer.ALIGN_BEGIN
		$"%HBoxContainer3".alignment = BoxContainer.ALIGN_BEGIN
		$"%Label".align = Label.ALIGN_RIGHT

func _process(delta):
	if is_instance_valid(fighter):
		hover_bar.value = fighter.hover_left / float(fighter.HOVER_AMOUNT)
		hover_bar.self_modulate.a = 0.25 if fighter.hover_left <= fighter.HOVER_MIN_AMOUNT else 1.0
	#	hover_bar.modulate.b = 0.5 if fighter.hovering else 1.0
		hover_bar.texture_progress = preload("res://characters/wizard/grav_bar3.png") if !fighter.hovering and !fighter.fast_falling else preload("res://characters/wizard/grav_bar4.png")
#		$"%GeyserLabel".text = "geyser: " + str(fighter.geyser_charge)
		for i in range(3):
			var droplet = get_node("%" + str((i + 1) if player_id == 2 else 3 - i))
			droplet.modulate.a = 1.0 if i < fighter.geyser_charge else 0.5
#		$"%SparkSpeed".visible = fighter.spark_speed_frames > 0
		$"%SparkSpeed".modulate.a = (1.0 if Utils.pulse(0.2, 0.75) else 0.6) if fighter.spark_speed_frames > 0 else 0.6
	
		flame_charge.max_value = fighter.FLAME_WAVE_COOLDOWN
		flame_charge.value = fighter.FLAME_WAVE_COOLDOWN - fighter.flame_wave_cooldown if fighter.can_flame_wave else 0
#		if flame_charge.value < flame_charge.max_value and flame_charge.texture_under != UNCHARGED_FLAME_SPRITE:
#			flame_charge.texture_under = UNCHARGED_FLAME_SPRITE
#		elif flame_charge.value == flame_charge.max_value and flame_charge.texture_under != CHARGED_FLAME_SPRITE:
#			flame_charge.texture_under = CHARGED_FLAME_SPRITE
