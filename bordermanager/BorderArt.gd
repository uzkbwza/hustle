extends Control


onready var char_texture_rects = {
	1: $"%CharacterLeft",
	2: $"%CharacterRight",
}
onready var bg_texture_rects = {
	1: $"%BackgroundLeft",
	2: $"%BackgroundRight",
}



func set_style_params(id, params):
	if char_texture_rects.has(id):
		if not (params is Dictionary):
			params = {}
		var material :ShaderMaterial = char_texture_rects[id].get_material()
		material.set_shader_param("use_extra_color_1", params.get("use_extra_color_1", false))
		material.set_shader_param("use_extra_color_2", params.get("use_extra_color_2", false))
		material.set_shader_param("extra_replace_color_1", params.get("extra_replace_color_1", Color.magenta))
		material.set_shader_param("extra_replace_color_2", params.get("extra_replace_color_2", Color.magenta))



func apply_style(id, style):
	if char_texture_rects.has(id):
		if not (style is Dictionary):
			style = {}
		var material :ShaderMaterial = char_texture_rects[id].get_material()
		material.set_shader_param("color", style.get("character_color", Color.white))
		material.set_shader_param("extra_color_1", style.get("extra_color_1", Color.white))
		material.set_shader_param("extra_color_2", style.get("extra_color_2", Color.white))
		material.set_shader_param("outline_color", style.get("outline_color", Color.black))
		material.set_shader_param("use_outline", style.get("use_outline", false))



func set_border_background(id, tex):
	if bg_texture_rects.has(id):
		bg_texture_rects[id].texture = tex



func set_border_art(id, tex):
	if char_texture_rects.has(id):
		char_texture_rects[id].texture = tex



func show_menu_art():
	$LeftChar.visible = false
	$RightChar.visible = false
	$ColorRect.visible = true
	


func show_character_art():
	$LeftChar.visible = true
	$RightChar.visible = true
	$ColorRect.visible = false

