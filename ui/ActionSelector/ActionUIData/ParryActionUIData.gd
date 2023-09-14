extends ActionUIData

onready var melee_parry_timing = $"Melee Parry Timing"
onready var h_slider = $"Melee Parry Timing/HSlider"

func on_opponent_button_selected(button):
	if button.get("earliest_hitbox") != null:
		h_slider.value = clamp(button.earliest_hitbox, 1, melee_parry_timing.max_value)
