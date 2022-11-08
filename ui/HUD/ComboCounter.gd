extends Control

export var player_id = 1

const SPACING = 32

const number_images = [
	preload("res://ui/ComboLevels/combo_level1.png"), 
	preload("res://ui/ComboLevels/combo_level2.png"), 
	preload("res://ui/ComboLevels/combo_level3.png"), 
	preload("res://ui/ComboLevels/combo_level4.png"), 
	preload("res://ui/ComboLevels/combo_level5.png"), 
	preload("res://ui/ComboLevels/combo_level6.png"), 
	preload("res://ui/ComboLevels/combo_level7.png"), 
	preload("res://ui/ComboLevels/combo_level8.png"), 
	preload("res://ui/ComboLevels/combo_level9.png"), 
	preload("res://ui/ComboLevels/combo_level10.png")
]

var current_combo = "0"

func set_combo(count_string: String):
	current_combo = count_string
	update()

func _draw():
	if int(current_combo) > 1:
		for i in range(len(current_combo)):
			var digit = int(current_combo[i])
			draw_texture(number_images[digit], Vector2(SPACING * i, 0))
