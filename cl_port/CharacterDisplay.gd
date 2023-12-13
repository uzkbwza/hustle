extends "res://ui/CSS/CharacterDisplay.gd"

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
