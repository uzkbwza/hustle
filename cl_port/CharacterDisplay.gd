extends "res://ui/CSS/CharacterDisplay.gd"

func _on_style_selected(style):
	emit_signal("style_selected", style)
	selected_style = style
	if aura_particle:
		aura_particle.queue_free()
		aura_particle = null
	var material = $"%CharacterPortrait".get_material()
	material.set_shader_param("color", Color.white)
	material.set_shader_param("use_outline", false)
	if style:
		Custom.apply_style_to_material(style, $"%CharacterPortrait".get_material(), true)

		if style.show_aura:
			var particle = preload("res://fx/CustomTrailParticle.tscn").instance()
			$"%CharacterPortrait".add_child(particle)
			particle.load_settings(style.aura_settings)
			particle.position = $"%CharacterPortrait".rect_size / 2
			particle.scale.x = - 1 if player_id == 2 else 1
			particle.facing = - 1 if player_id == 2 else 1
			aura_particle = particle
			pass

func load_character_data(data):
	$"%CharacterPortrait".texture = data["portrait"]
	var n = data["name"]
	if (n[0] == "F" and n[1] == "-"):
		var list = n.split("__")
		n = list[1]
	get_node("CharacterLabel").align = 1
	theme = load("res://theme.tres")
	if ("ERROR" in n):
		n = n.replace("DOTCHAR", ".").replace("SLASHCHAR", "/").replace("SLASHCHAR", "-").replace("COLONCHAR", ":")
		get_node("CharacterLabel").align = 0
		theme = load("res://cl_port/visuals/error.tres")
	$"%CharacterLabel".text = n
	if data.get("use_extra_color_1"):
		$"%CharacterPortrait".get_material().set_shader_param("extra_replace_color_1", data.get("extra_color_1"))
	if data.get("use_extra_color_2"):
		$"%CharacterPortrait".get_material().set_shader_param("extra_replace_color_2", data.get("extra_color_2"))