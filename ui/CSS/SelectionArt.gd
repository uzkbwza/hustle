extends Control



onready var char_texture_rects = {
	1: $"%CharacterLeft",
	2: $"%CharacterRight",
}
onready var bg_texture_rects = {
	1: $"%BackgroundLeft",
	2: $"%BackgroundRight",
}
onready var sfx_nodes = {
	1: [$"%LeftSFX1", $"%LeftSFX2"],
	2: [$"%RightSFX1", $"%RightSFX2"],
}

export var default_background : Texture

var default_extra_1 = { 1:Color.white, 2:Color.white }
var default_extra_2 = { 1:Color.white, 2:Color.white }
var applied_styles = { 1:null, 2:null }

var swap_sides = false



func _ready():
	for player_id in sfx_nodes:
		for node in sfx_nodes[player_id]:
			node.get_node("Timer").connect("timeout", node, "play")
	reset()



func reset():
	$"%LeftAnimPlayer".play("RESET")
	$"%RightAnimPlayer".play("RESET")
	$"%LeftLoadingAnimPlayer".play("RESET")
	$"%RightLoadingAnimPlayer".play("RESET")
	
	set_style_params(1, null)
	set_style_params(2, null)
	apply_style(1, null)
	apply_style(2, null)
	
	for player_id in sfx_nodes:
		for node in sfx_nodes[player_id]:
			node.stop()
			node.get_node("Timer").stop()



func animate_reveal(id :int):
	var anim_player = $"%LeftAnimPlayer" if id == 1 else $"%RightAnimPlayer"
	anim_player.play("reveal")
	BorderManager.set_border_color(id, BorderManager.dark_color)



func animate_unreveal(id :int):
	var anim_player = $"%LeftAnimPlayer" if id == 1 else $"%RightAnimPlayer"
	anim_player.play("RESET")
	BorderManager.set_border_color(id, BorderManager.menu_color)



func animate_load_started(id :int):
	var anim_player = $"%LeftLoadingAnimPlayer" if id == 1 else $"%RightLoadingAnimPlayer"
	anim_player.play("loop")



func animate_load_done(id :int):
	var anim_player = $"%LeftLoadingAnimPlayer" if id == 1 else $"%RightLoadingAnimPlayer"
	anim_player.play("load_done")



func set_style_params(id, params):
	if char_texture_rects.has(id):
		if not (params is Dictionary):
			params = {}
		var material :ShaderMaterial = char_texture_rects[id].get_material()
		
		var use_extra_1 = params.get("use_extra_color_1", false)
		material.set_shader_param("use_extra_color_1", use_extra_1)
		var extra_replace_1 = params.get("extra_replace_color_1", params.get("extra_color_1", Color.magenta))
		material.set_shader_param("extra_replace_color_1", extra_replace_1)
		
		if default_extra_1.has(id):
			default_extra_1[id] = extra_replace_1 if use_extra_1 else Color.white
		
		var use_extra_2 = params.get("use_extra_color_2", false)
		material.set_shader_param("use_extra_color_2", use_extra_2)
		var extra_replace_2 = params.get("extra_replace_color_2", params.get("extra_color_2", Color.magenta))
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
			2: default_color = Fighter.P2_COLOR
		material.set_shader_param("color", style.get("character_color", default_color))
		material.set_shader_param("extra_color_1", style.get("extra_color_1", default_extra_1.get(id, Color.white)))
		material.set_shader_param("extra_color_2", style.get("extra_color_2", default_extra_2.get(id, Color.white)))
		material.set_shader_param("outline_color", style.get("outline_color", Color.black))
		material.set_shader_param("use_outline", style.get("use_outline", false))



func set_background(id, tex : Texture):
	if tex == null:
		tex = default_background
	if bg_texture_rects.has(id):
		bg_texture_rects[id].texture = tex



func set_portrait(id, tex : Texture):
	if char_texture_rects.has(id):
		char_texture_rects[id].texture = tex



func set_sfx_data(id, sfx_data : Array):
	if not sfx_nodes.has(id):
		return
	var side_sfx_nodes = sfx_nodes[id]
	var sound_num = 0
	for entry in sfx_data:
		if not (entry is Dictionary):
			continue
		var used_sfx_node = side_sfx_nodes[sound_num]
		var sfx_timer :Timer = used_sfx_node.get_node("Timer")
		
		used_sfx_node.pitch_variation = entry.get("pitch_variation", 0.1)
		used_sfx_node.stream = entry.get("sfx", null)
		used_sfx_node.volume_db = entry.get("volume_db", -10)
		sfx_timer.wait_time = max(entry.get("delay", 0), 0.00001)
		sfx_timer.start()
		
		sound_num += 1
		if sound_num >= 2: # max sounds
			break

