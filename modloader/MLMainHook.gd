extends Node

func _ready():
	_addModToggle(ModLoader.active)
	if ModLoader.active:
		#old
		#_addModList()
		#_addMisingList()

		var menu = _add_modlist()
		_populate_mod_menu(menu)
		_addMisingList()
		if ModLoader.charLoaderModDetected:
			ModLoader.charLoaderModDetected = false
			_add_char_loader_warning()

#Creates mod menu and places it in the options container
func _add_modlist():
	var menu = load("res://modloader/ModLoaderMenu.tscn").instance()
	var credits = load("res://modloader/ModLoaderCredits.tscn").instance()
	var uilayer = $"%OptionsContainer/.."
	uilayer.add_child_below_node($"%OptionsContainer", credits, true)
	uilayer.add_child_below_node($"%OptionsContainer", menu, true)
	menu.connect("uploader_clicked", uilayer, "on_workshop_uploader_clicked")
	var btn:Node = addMainMenuButton("Mod List")
	btn.connect("pressed", menu, "_mainmenu_button_pressed")
	return menu

func _add_char_loader_warning():
	var container = addContainer("CharLoaderWarning", "Alert")
	var close = generateButton("Close")
	close.connect("pressed", container, "hide")
	container.get_node("VBoxContainer").get_node("TitleBar").get_node("Title").add_child(close)
	var label = Label.new()
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	container.list_container.add_child(label)

	label.text = "The Character Loader mod has been disabled, as its functionality is now present in the base game. To disable this popup, please uninstall the mod."
	label.autowrap = true
	container.show()

#Calls function from ModLoaderMenu.gd to populate list of mods
func _populate_mod_menu(menu):
	for mod in ModLoader.active_mods:
		menu.add_mod(mod)
	
func _addModList():
	# add the mod list container
	var list = addContainer("ModListContainer", "Mod List")

	# add the contents into it
	var close = generateButton("Close")
	
	# close button function
	close.connect("pressed", self, "_modlist_closebutton_pressed")
	
	# add close button to title bar
	list.get_node("VBoxContainer").get_node("TitleBar").get_node("Title").add_child(close)
	# add list into contents
	var xbox = VBoxContainer.new()
	xbox.name = "XBoxContainer"
	
	var label = Label.new()
	label.text = "ModLoader by ZT2wo#9157 and Ted#0420"
	label.align = Label.ALIGN_CENTER
	label.modulate.a = 0.25
	list.list_container.add_child(label)
	#list.get_node("VBoxContainer").get_node("Contents").add_child(xbox)
	# add content into contents list
	for entry in ModLoader.active_mods:
		var mod = entry.duplicate()
		var info = addContainer("ModInfoContainer", "Mod Info")
		var modclose = generateButton("Close")
		#var b = generateLabel(mod[2].friendly_name, 1) # generate a button with that name ## 1 = ALIGN_CENTER
		if mod.size() > 2:
			mod.pop_at(1)
		var b = generateButton(mod[1].friendly_name)
		list.list_container.add_child(b) # and add it
		b.connect("pressed", self, "_mod_button_pressed", [info])
		modclose.connect("pressed", self, "_mod_closebutton_pressed", [info])
		info.get_node("VBoxContainer").get_node("TitleBar").get_node("Title").add_child(modclose)
		var xbox2 = VBoxContainer.new()
		xbox2.name = "XBoxContainer"

		#Create contents 
		info.get_node("VBoxContainer").get_node("Contents").add_child(xbox2)
		var name = "Name: " + mod[1].friendly_name
		var name_lab = generateLabel(name, 0)
		var desc_header = generateLabel("Description: ", 0)
		var desc = mod[1].description
		var desc_lab = generateRichLabel(desc)
		var auth = "Author: " + mod[1].author
		var auth_lab = generateLabel(auth, 0)
		var ver = "Version: " + mod[1].version
		var ver_lab = generateLabel(ver, 0)
		var infoBox = info.get_node("VBoxContainer").get_node("Contents").get_node("XBoxContainer")
		infoBox.add_child(name_lab)
		infoBox.add_child(auth_lab)
		infoBox.add_child(ver_lab)
		infoBox.add_child(desc_header)
		infoBox.add_child(desc_lab)
		if mod[1].requires != [""]:
			var req = "Requires: " + str(mod[1].requires)
			var req_lab = generateLabel(req, 0)
			info.get_node("VBoxContainer").get_node("Contents").get_node("XBoxContainer").add_child(req_lab)

	#Shows the mods that are disabled because of missing dependencies
	for missing in ModLoader.mods_w_missing_depend:
		var b = generateButton(missing + " (Disabled Missing Dependencies)")
		b.set("custom_colors/font_color_disabled", Color(1,0,0,.8))
		b.disabled = true
		list.list_container.add_child(b) # and add it
	
	# add the button into the main menu
	var btn = addMainMenuButton("Mod List")
	# function for the button
	btn.connect("pressed", self, "_modlist_button_pressed")

#Main Menu button and Mod Toggle
#needed
func addMainMenuButton(_text):
	# generating the button
	var button_mainmenu = generateButton(_text)
	# adding it to the scene
	button_mainmenu.flat = false
	$"%MainMenu".get_node("ModListButtonContainer").add_child(button_mainmenu, true)
	
	return button_mainmenu
	
#needed
func _addModToggle(moddedState):
	var modToggleBtn = $"%ModToggle"
	modToggleBtn.pressed = moddedState
	modToggleBtn.connect("pressed", self, "_toggle_mods_active", [modToggleBtn])
	
#needed
func _toggle_mods_active(btn):
	var file = File.new()
	var moddedState = {"modsEnabled":btn.pressed}
	file.open("user://modded.json", File.WRITE)
	file.store_string(JSON.print(moddedState, "  "))
	file.close()

func generateContainer(name_gen):
	var _container = preload("res://modloader/ModLoaderWindow.tscn").instance()
	_container.name = name_gen
	return _container

func generateLabel(text_gen, align):
	var _label = Label.new()
	_label.text = text_gen
	_label.align = align
	return _label

func generateRichLabel(text_gen):
	var _richLabel = load("res://modloader/ModdedRichText.gd").new()
	_richLabel.bbcode_enabled= true
	_richLabel.bbcode_text = text_gen
	var pulseFX = RichTextPulse.new()
	var rainFX = RichTextRain.new()
	var ghostFX = RichTextGhost.new()
	_richLabel.install_effect(pulseFX)
	_richLabel.install_effect(rainFX)
	_richLabel.install_effect(ghostFX)
	return _richLabel

func generateButton(text_gen):
	var _button = Button.new()
	_button.text = text_gen
	_button.flat = true
	_button.set("mouse_default_cursor_shape", 2) #CURSOR_POINTING_HAND
	_button.set("custom_colors/font_color_hover", Color(100.0, 0.2, 0.23, 1.0))
	return _button

func generateCheckButton(text_gen):
	var _checkButton = CheckButton.new()
	_checkButton.text = text_gen
	return _checkButton


func addContainer(_name, _text):
	var container = generateContainer(_name)
	$"%MainMenu".add_child(container)
	container.get_node("VBoxContainer").get_node("TitleBar").get_node("Title").text = _text
	container.set("visible", false)
	return container
	
func _addMisingList():
	var mod_w_missing = ModLoader.mods_w_missing_depend
	var list = addContainer("ModMissingContainer", "Mod Missing Dependecies")
	var close = generateButton("Close")
	close.connect("pressed", list, "hide")
	list.get_node("VBoxContainer").get_node("TitleBar").get_node("Title").add_child(close)
	if mod_w_missing.size() > 0:
		for missing in mod_w_missing:
			var label = Label.new()
			label.text = missing + ": Missing Dependency: " + str(mod_w_missing.get(missing))
			list.list_container.add_child(label)
		$"%MainMenu".get_node("ModMissingContainer").set("visible", true)

