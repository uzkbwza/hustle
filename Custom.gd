extends Node

var hitsparks = {
	"bash": "res://fx/HitEffect1.tscn",
	"bash2": "res://fx/hitsparks/HitEffect1Alt.tscn",
}

var hitspark_dlc = {
	"bash": 0,
	"bash2": 0,
}

var p1_selected_style = null
var p2_selected_style = null

var simple_colors = ["94e4ff", "ffc1a1", "ecffa4", "fec2ff", "6e8696", "ffea5d", "04579a", "85001f", "008561", "9f42ba", "343537", "ff9444"]
var simple_outlines = ["04579a", "85001f", "008561", "9f42ba", "343537", "ff9444", "94e4ff", "ffc1a1", "ecffa4", "fec2ff", "6e8696", "ffea5d"]

func _ready():
	make_custom_folder()
	
func make_custom_folder():
	var dir = Directory.new()
	if !dir.dir_exists("user://custom"):
		dir.make_dir("user://custom")

func apply_style_to_material(style, material: ShaderMaterial):
	material.set_shader_param("color", style.character_color)
	material.set_shader_param("use_outline", style.use_outline)
	material.set_shader_param("outline_color", style.outline_color)
	pass


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

func save_style(style):
	make_custom_folder()
	var file = File.new()
	file.open("user://custom/"+ style.style_name + ".style", File.WRITE)
	file.store_var(style, true)
	file.close()

func load_all_styles():
	make_custom_folder()
	var dir = Directory.new()
	var files = []
	var _directories = []
	var styles = []
	dir.open("user://custom")
	dir.list_dir_begin(false, true)
#	print(dir.get_current_dir())
	Global.add_dir_contents(dir, files, _directories, false)
	for path in files:
		var file = File.new()
		file.open(path, File.READ)
		var data: Dictionary = file.get_var()
		styles.append(data)
		file.close()
	return styles
