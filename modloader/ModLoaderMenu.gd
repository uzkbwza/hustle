extends Window

signal uploader_clicked()

var ModOptions
var current_mod = null
var mod_tabs:Dictionary = {}

onready var list_container = $VBoxContainer/Contents/HBoxContainer/ScrollContainer/Mods
onready var info_container = $VBoxContainer/Contents/HBoxContainer/ModInfoContainer

var userdata := {}
var late_inited = false
var needs_to_save = false


# Called when the node enters the scene tree for the first time.
func _ready():
	hint_tooltip=""
	#ModOptions = load("res://modloader/ModOptions.gd").new()
	#ModOptions.menu = self
	#get_tree().get_current_scene().call_deferred("add_child", ModOptions, true)
	$"%Close".connect("pressed", self, "_close_clicked")
	$"%ModsLocation".connect("pressed", self, "_open_mods_folder")
	$"%ModCredits".connect("pressed", self, "_credits_clicked")
	$"%WorkshopUploader".connect("pressed", self, "_uploader_clicked")
	$"%WorkshopButton".connect("pressed", self, "_workshop_clicked")
	
	Global.connect("mobile_ui_changed", self, "adjust_ui")
	adjust_ui(Global.mobile_ui)
	
	hide()


func adjust_ui(is_mobile):
	$"%WorkshopUploader".visible = not is_mobile
	$"%WorkshopButton".visible = not is_mobile


func _open_mods_folder():
	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
	var modPathPrefix = gameInstallDirectory.plus_file("mods")
	OS.shell_open(modPathPrefix)

func _uploader_clicked():
	hide()
	emit_signal("uploader_clicked")

func _workshop_clicked():
#	hide()
	Steam.activateGameOverlayToWebPage("https://steamcommunity.com/app/2212330/workshop/")
#	emit_signal("uploader_clicked")

func _credits_clicked():
	get_node("/root/Main/UILayer/ModLoaderCredits").show()
	get_node("/root/Main/UILayer/ModLoaderCredits").raise()
	
func _close_clicked():
	hide()
	if current_mod:
		current_mod.hide()

func generate_info():
	pass

func _mainmenu_button_pressed():
	show()

func generate_mod_menu(_name):
	# Need to format the objects to look like the scene temp stuff
	var _container = TabContainer.new()
	_container.tab_align = 0
	var mod_info = VBoxContainer.new()
	mod_info.set_h_size_flags(3)
	mod_info.set_v_size_flags(1)
	#var mod_options_cont = ScrollContainer.new()
	#var mod_options = VBoxContainer.new()
	#mod_options.set_h_size_flags(3)
	#mod_options.set_v_size_flags(1)

	_container.name = _name
	#mod_options_cont.add_child(mod_options, true)
	_container.add_child(mod_info, true)
	#_container.add_child(mod_options_cont, true)
	_container.set_tab_title(0, "Mod Info")
	#_container.set_tab_title(1, "Mod Options")
	_container.set("visible", false)
	return _container

#Creates button in mod list and mod info tab
#TODO make look better and add toggle for each mod
func add_mod(mod):
	#Generate button
	var _container = HBoxContainer.new()
	_container.set_h_size_flags(3)
	_container.set_v_size_flags(1)
	
	var btn = generateButton(mod[1].friendly_name)
	var toggle = generateButton("", false, 1)
	
	_container.name = mod[1].friendly_name
	_container.add_child(btn, true)
	_container.add_child(toggle, true)
	
	var is_mod_active =  mod in ModLoader.active_mods
	toggle.pressed = is_mod_active
	
	#Add button container to $mods
	self.list_container.add_child(_container)
	# Generate tab container
	var info = generate_mod_menu(mod[1].friendly_name)
	self.info_container.add_child(info)

	#Connect button
	btn.connect("pressed", self, "_tab_clicked", [info])
	toggle.connect("toggled", self, "_toggle_clicked", [mod, toggle, btn])

	#Populate mod info tab
	var name = "Name: " + mod[1].friendly_name
	var name_lab = generateLabel(name, 0)
	var desc = "Description: " + mod[1].description
	var desc_lab = generateRichLabel(desc)
	var auth = "Author: " + mod[1].author
	var auth_lab = generateLabel(auth, 0)
	var ver = "Version: " + mod[1].version
	var ver_lab = generateLabel(ver, 0)
	info.get_node("VBoxContainer").add_child(desc_lab)
	info.get_node("VBoxContainer").add_child(auth_lab)
	info.get_node("VBoxContainer").add_child(ver_lab)
	if mod[1].requires != [""]:
		printt("mod info",mod[1].name,mod[1].requires)
		var req = "Requires: " + str(mod[1].requires)
		var req_lab = generateLabel(req, 0)
		info.get_node("VBoxContainer").add_child(req_lab)
	
	#Populate mod options tab
	#info.get_node("ScrollContainer/VBoxContainer").add_child()

func show_menu(node:Node):
	if current_mod != null:
		current_mod.hide()
		#current_mod.tab_btn.pressed = false
	node.show()
	#node.tab_btn.pressed = true
	current_mod = node

func _tab_clicked(node:Node):
	if current_mod != node:
		show_menu(node)


func _toggle_clicked(_button_pressed: bool, _mod, _toggle, _button):
	var is_mod_active =  _mod in ModLoader.active_mods
	
	$"%FileManager".current_list[_mod] = [_button_pressed, is_mod_active]
	
	_button.add_color_override("font_color", Color("ff333b" if _button_pressed != is_mod_active else "ffffff"))
	

func generateButton(text_gen, _is_button = true, _h_size_flag: int = 3, _v_size_flag:int = 1 ):
	var _button = Button.new() if _is_button else CheckButton.new()
	_button.text = text_gen
	_button.flat = true
	_button.set("mouse_default_cursor_shape", 2) #CURSOR_POINTING_HAND
	_button.set("custom_colors/font_color_hover", Color(100.0, 0.2, 0.23, 1.0))
	_button.set_h_size_flags(_h_size_flag)
	_button.set_v_size_flags(_v_size_flag)
	_button.add_color_override("font_color", Color("ffffff"))
	return _button

func generateLabel(text_gen, align):
	var _label = Label.new()
	_label.text = text_gen
	_label.align = align
	_label.autowrap = true
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

func add_menu_from_node(menuNode):
	var menuButton = load("res://SoupModOptions/MOTabBtn.gd").new()
	menuButton.toggle_mode = true
	menuButton.text = menuNode.tab_name
	#menuButton.flat = true
	menuButton.set("mouse_default_cursor_shape", 2)
	#menuButton.set("custom_colors/font_color_hover", Color(100.0, 0.2, 0.23, 1.0))
	menuNode.tab_btn = menuButton
	menuNode.visible = false
	menuButton.menu_node = menuNode
	menuButton.connect("pressed", self, "_tab_clicked", [menuButton])
	mod_tabs[menuNode.name] = menuNode
	$"%Tabs".add_child(menuButton)
	menuButton.set_theme_type_variation("TabButton")
	$"%MenuContainer".add_child(menuNode)
