extends Node
# MODLOADER V1.1 


func _ready(): # on ready,

	_addModToggle(ModLoader.active)
	if ModLoader.active:
		_addModList()
	
func _addModList():
	# add the mod list container and
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
#	list.get_node("VBoxContainer").get_node("Contents").add_child(xbox)
	# add content into contents list
	for mod in ModLoader.active_mods:
		var info = addContainer("ModInfoContainer", "Mod Info")
		var modclose = generateButton("Close")
		#var b = generateLabel(mod[2].friendly_name, 1) # generate a button with that name ## 1 = ALIGN_CENTER
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
		var desc = "Description: " + mod[1].description
		var desc_lab = generateLabel(desc, 0)
		var auth = "Author: " + mod[1].author
		var auth_lab = generateLabel(auth, 0)
		var ver = "Version: " + mod[1].version
		var ver_lab = generateLabel(ver, 0)
		info.get_node("VBoxContainer").get_node("Contents").get_node("XBoxContainer").add_child(name_lab)
		info.get_node("VBoxContainer").get_node("Contents").get_node("XBoxContainer").add_child(desc_lab)
		info.get_node("VBoxContainer").get_node("Contents").get_node("XBoxContainer").add_child(auth_lab)
		info.get_node("VBoxContainer").get_node("Contents").get_node("XBoxContainer").add_child(ver_lab)
		if mod[1].requires != [""]:
			var req = "Requires: " + str(mod[1].requires)
			var req_lab = generateLabel(req, 0)
			info.get_node("VBoxContainer").get_node("Contents").get_node("XBoxContainer").add_child(req_lab)
	# add the button into the main menu
	var btn = addMainMenuButton("Mod List")
	# function for the button
	btn.connect("pressed", self, "_modlist_button_pressed")

func _addModToggle(moddedState):
	var modToggleBtn = $"%ModToggle"
	modToggleBtn.pressed = moddedState
	modToggleBtn.connect("pressed", self, "_toggle_mods_active", [modToggleBtn])
	

func _toggle_mods_active(btn):
	var file = File.new()
	var moddedState = {"modsEnabled": btn.pressed}
	file.open("user://modded.json", File.WRITE)
	file.store_string(JSON.print(moddedState, "  "))
	file.close()

func _modlist_button_pressed():
	$"%MainMenu".get_node("ModListContainer").set("visible", true)

func _modlist_closebutton_pressed():
	$"%MainMenu".get_node("ModListContainer").set("visible", false)

func _mod_button_pressed(panel):
	panel.set("visible", true)
	panel.raise()

func _mod_closebutton_pressed(panel):
	panel.set("visible", false)

func generateContainer(name_gen):
	var _container = preload("res://modloader/ModLoaderWindow.tscn").instance()
	_container.name = name_gen
	return _container

func generateLabel(text_gen, align):
	var _label = Label.new()
	_label.text = text_gen
	_label.align = align
	return _label

func generateButton(text_gen):
	var _button = Button.new()
	_button.text = text_gen
	_button.flat = true
	_button.set("mouse_default_cursor_shape", 2) #CURSOR_POINTING_HAND
	_button.set("custom_colors/font_color_hover", Color(100.0, 0.20, 0.23, 1.0))
	return _button

func generateCheckButton(text_gen):
	var _checkButton = CheckButton.new()
	_checkButton.text = text_gen
	return _checkButton
	
func addMainMenuButton(_text):
	# generating the button
	var button_mainmenu = generateButton(_text)
	# adding it to the scene
	button_mainmenu.rect_min_size.y = 20
	$"%MainMenu".get_node("ButtonContainer").add_child(button_mainmenu, true)
	$"%MainMenu".get_node("ButtonContainer").move_child(button_mainmenu, 4)
	
	return button_mainmenu
	
func addContainer(_name, _text):
	# generating the mod list container
	var container = generateContainer(_name)
	# adding it to the scene
	$"%MainMenu".add_child(container)
	# setting the stuffs //TODO: do this better somehow? it seems scuffed
	container.get_node("VBoxContainer").get_node("TitleBar").get_node("Title").text = _text
	# hiding it
	container.set("visible", false)
	# return it for use later
	return container
