extends Control


onready var char_texture_rects = {
	1: $"%CharacterLeft",
	2: $"%CharacterRight",
}
onready var bg_texture_rects = {
	1: $"%BackgroundLeft",
	2: $"%BackgroundRight",
}
onready var color_rects = {
	1: $LeftColorRect,
	2: $RightColorRect,
}

export var default_background : Texture

var default_extra_1 = { 1:Color.white, 2:Color.white }
var default_extra_2 = { 1:Color.white, 2:Color.white }
var applied_styles = { 1:null, 2:null }



func set_style_params(id, params):
	if char_texture_rects.has(id):
		if not (params is Dictionary):
			params = {}
		var material :ShaderMaterial = char_texture_rects[id].get_material()
		
		var use_extra_1 = params.get("use_extra_color_1", false)
		material.set_shader_param("use_extra_color_1", use_extra_1)
		var extra_replace_1 = params.get("extra_replace_color_1", Color.magenta)
		material.set_shader_param("extra_replace_color_1", extra_replace_1)
		
		if default_extra_1.has(id):
			default_extra_1[id] = extra_replace_1 if use_extra_1 else Color.white
		
		var use_extra_2 = params.get("use_extra_color_2", false)
		material.set_shader_param("use_extra_color_2", use_extra_2)
		var extra_replace_2 = params.get("extra_replace_color_2", Color.magenta)
		material.set_shader_param("extra_replace_color_2", extra_replace_2)
		
		if default_extra_2.has(id):
			default_extra_2[id] = extra_replace_2 if use_extra_2 else Color.white
		
		apply_style(id, applied_styles[id])



func apply_style(id, style):
	if char_texture_rects.has(id):
		applied_styles[id] = style
		if not (style is Dictionary):
			style = {}
		var material :ShaderMaterial = char_texture_rects[id].get_material()
		var default_color = Color.white
		match id:
			1: default_color = Fighter.P1_COLOR
			2:default_color = Fighter.P2_COLOR
		material.set_shader_param("color", style.get("character_color", default_color))
		material.set_shader_param("extra_color_1", style.get("extra_color_1", default_extra_1.get(id, Color.white)))
		material.set_shader_param("extra_color_2", style.get("extra_color_2", default_extra_2.get(id, Color.white)))
		material.set_shader_param("outline_color", style.get("outline_color", Color.black))
		material.set_shader_param("use_outline", style.get("use_outline", false))



func set_border_background(id, tex):
	if tex == null:
		tex = default_background
	if bg_texture_rects.has(id):
		bg_texture_rects[id].texture = tex



func set_border_art(id, tex):
	if char_texture_rects.has(id):
		char_texture_rects[id].texture = tex



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
