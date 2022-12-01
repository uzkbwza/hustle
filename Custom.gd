extends Node

var hitsparks = {
	"bash": "res://fx/HitEffect1.tscn",
	"bash2": "res://fx/hitsparks/HitEffect1Alt.tscn",
}

var hitspark_dlc = {
	"bash": 0,
	"bash2": 0,
}

var simple_colors = ["94e4ff", "ffc1a1", "ecffa4", "fec2ff", "04579a", "85001f", "008561", "9f42ba", "6e8696", "ffea5d", "343537", "ff9444"]
var simple_outlines = ["04579a", "85001f", "008561", "9f42ba", "94e4ff", "ffc1a1", "ecffa4", "fec2ff", "343537", "ff9444", "6e8696", "ffea5d"]

func is_combo_simple(color, outline):
	return simple_colors.find(color) == simple_outlines.find(outline)

func is_color_dlc(color):
	if color is Color:
		return color.to_html(false) in simple_colors
	return color in simple_colors

func is_outline_dlc(color):
	if color is Color:
		return color.to_html(false) in simple_outlines
	return color in simple_outlines

func hitspark_to_dlc(spark_name):
	if spark_name in hitspark_dlc:
		return hitspark_dlc[spark_name]
	return 0

func requires_dlc(data):
	if data.show_aura:
		return true
	if is_color_dlc(data.character_color):
		return true
	if data.use_outline and is_outline_dlc(data.outline_color):
		return true
	if data.use_outline and !is_combo_simple(data.character_color, data.outline_color):
		return true
	if hitspark_to_dlc(data.hitspark) != 0:
		return true
	return false

func save_custom(custom):
	pass
