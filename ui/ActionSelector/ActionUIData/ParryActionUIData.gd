extends ActionUIData

onready var melee_parry_timing = $"Melee Parry Timing"
onready var h_slider = $"Melee Parry Timing/HSlider"
onready var block_height = $"Block Height"

func on_button_selected():
	var button = action_buttons.opponent_action_buttons.current_button
	if button:
		if button.get("earliest_hitbox") != null:
			h_slider.value = clamp(button.earliest_hitbox, 1, melee_parry_timing.max_value)
			if button.state and button.state.get("earliest_hitbox_node") != null:
				var hit_height = button.state.earliest_hitbox_node.hit_height
				if hit_height == Hitbox.HitHeight.Low:
					block_height.set_dir_from_data({"x": fighter.get_facing_int(), "y": 1})
				else:
					block_height.set_dir_from_data({"x": fighter.get_facing_int(), "y": 0})
