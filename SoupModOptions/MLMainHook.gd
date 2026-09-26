extends "res://modloader/MLMainHook.gd"

func _ready():
	_add_mod_options_menu()
	yield(get_node("../.."), "ready")
	call_deferred("late_init")

func _add_mod_options_menu():
	var menu = load("res://SoupModOptions/ModOptionsMenu.tscn").instance()
	var uilayer = $"%OptionsContainer/.."
	uilayer.add_child_below_node($"%OptionsContainer", menu, true)
	
	var btn:Node = addMainMenuButton("Mod Options")
	
	btn.connect("pressed", menu, "_mainmenu_button_pressed")

# Late init
#var __modoptions_late_inited = false
#
#func _process(delta):
#	if !__modoptions_late_inited:
#		var ModOptions = get_node("ModOptions")
#		for key in ModOptions.menu.menus:
#			ModOptions.menu.menus[key].emit_signal("late_init")
#		__modoptions_late_inited = true

func late_init():
	var ModOptions = get_node("../../ModOptions")
	for key in ModOptions.menu.menus:
		ModOptions.menu.menus[key].emit_signal("late_init")
