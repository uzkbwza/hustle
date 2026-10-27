extends "res://bordermanager/FullArtManager.gd"



onready var color_rects = {
	1: $LeftColorRect,
	2: $RightColorRect,
}



func show_menu_art():
	$LeftChar.visible = false
	$RightChar.visible = false
	$LeftColorRect.visible = true
	$RightColorRect.visible = true



func show_character_art():
	$LeftChar.visible = true
	$RightChar.visible = true
	$LeftColorRect.visible = false
	$RightColorRect.visible = false



func set_border_color(id, col : Color):
	if color_rects.has(id):
		color_rects[id].color = col
