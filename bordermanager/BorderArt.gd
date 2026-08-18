extends Control



func style_params(right_side, params):
	pass


func apply_style(right_side, style):
	pass



func set_border_background(right_side, tex):
	if right_side:
		$"%BackgroundRight".texture = tex
	else:
		$"%BackgroundLeft".texture = tex



func set_border_art(right_side, tex):
	if right_side:
		$"%CharacterRight".texture = tex
	else:
		$"%CharacterLeft".texture = tex



func show_menu_art():
	$LeftChar.visible = false
	$RightChar.visible = false
	$ColorRect.visible = true
	


func show_character_art():
	$LeftChar.visible = true
	$RightChar.visible = true
	$ColorRect.visible = false

