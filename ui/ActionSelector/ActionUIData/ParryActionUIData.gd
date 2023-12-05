extends ActionUIData

onready var melee_parry_timing = $"Melee Parry Timing"
onready var h_slider = $"Melee Parry Timing/HSlider"
onready var block_height = $"Block Height"

func init():
	.init()
	block_height.set_height(true)
	on_button_selected()


func on_button_selected():
	melee_parry_timing.show()
	if fighter.combo_count > 0:
		h_slider.value = 2
		block_height.set_height(true)
	var button = action_buttons.opponent_action_buttons.current_button
	if button:
		if button.get("earliest_hitbox") != null and button.earliest_hitbox > 0:
			h_slider.value = clamp(button.earliest_hitbox, 1, melee_parry_timing.max_value)
			if button.state and button.state.get("earliest_hitbox_node") != null:
				var hit_height = button.state.earliest_hitbox_node.hit_height
				block_height.set_height(hit_height != Hitbox.HitHeight.Low)
#
	if state and (state.get("reblock")):
		melee_parry_timing.hide()
		$"%CantParry".show()
