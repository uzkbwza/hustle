extends Window


signal uploader_clicked()

var ModOptions
var current_mod = null
var mod_tabs:Dictionary = {}
var mods: Dictionary = {}
var userdata := {}
var late_inited = false
var needs_to_save = false

var cur_sort = FileManager.SortMode.NAME
var cur_sort_inverted := false

onready var list_container = $VBoxContainer/Contents/HBoxContainer/ScrollContainer/Mods
onready var info_container = $VBoxContainer/Contents/HBoxContainer/ModInfoContainer
onready var file_manager: FileManagerInterface = $FileManagerInterface


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
	$"%ApplyChanges".connect("pressed", self, "_on_apply_changes_pressed")
	$"%Sorter".connect("pressed", self, "_on_sorter_pressed")
	$"%SortInvert".connect("toggled", self, "_on_sort_invert_toggled")
	$"%OpenFileManager".connect("pressed", self, "_open_file_manager")

	Global.connect("mobile_ui_changed", self, "adjust_ui")
	adjust_ui(Global.mobile_ui)

	_setup_file_manager()

	hide()


func _setup_file_manager() -> void:
	file_manager.connect("get_data_requested", self, "_on_fm_get_data_requested")
	file_manager.connect("apply_data_requested", self, "_on_fm_apply_data_requested")
	file_manager.connect("get_listed_requested", self, "_on_fm_get_listed_requested")
	file_manager.connect("folder_updated", self, "_on_fm_folder_updated")
	
	# On desktop mods live next to the executable (use_game_folder=true),
	# which matches what _loadMods() uses. On Android the APK dir is
	# read-only so we must write to user://mods instead.
	file_manager.setup("mods", PoolStringArray([".zip", ".ymhpack"]),
		not Global.is_mobile_device)
	
	# FileManagerInterface no longer manages external buttons itself -
	# wire its own open/close directly. %Close still also runs
	# _close_clicked() below, so one press closes both windows.
	$"%Close".connect("pressed", file_manager, "_on_close_pressed")


func _loadMods():
	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
	var modPathPrefix = gameInstallDirectory.plus_file("mods")
	_load_mods_in_folder(modPathPrefix)

	var dir2 = Directory.new()
	var _directories = []
	var workshop = SteamWorkshop.new()
	for item in Steam.getSubscribedItems():
		var info : Dictionary
		info = workshop.get_item_install_info(item)
		if info.ret:
			_load_mods_in_folder(info.folder, true)

	# surely this is just a simple addition! later i shall make it work for pc too - vineraio
	if Global.is_mobile_device:
		_load_mods_in_folder("user://mods", true)


func _load_mods_in_folder(modPathPrefix, zip_only=false):
	print("loading mods in folder: " + modPathPrefix)
	var dir = Directory.new()
	if dir.open(modPathPrefix) != OK:
		return
	if dir.list_dir_begin() != OK:
		return

	var _modZipFiles = []

	while true:
		var fileName = dir.get_next()
		if fileName == '':
			break
		if dir.current_is_dir():
			continue
		var modFSPath: String = modPathPrefix.plus_file(fileName)
		if zip_only and modFSPath.get_extension() != "zip":
			continue
		var modGlobalPath = ProjectSettings.globalize_path(modFSPath)
		if !ProjectSettings.load_resource_pack(modGlobalPath, true):
			continue
		_modZipFiles.append(modFSPath)

	for mod_path in _modZipFiles:
		refresh_mod(mod_path)


func _open_file_manager():
	file_manager._on_open_pressed()


func _on_sorter_pressed():
	match cur_sort:
		FileManager.SortMode.NAME:
			cur_sort = FileManager.SortMode.DATE
			$"%Sorter".text = "Sort: Date"
		FileManager.SortMode.DATE:
			cur_sort = FileManager.SortMode.ACTIVE
			$"%Sorter".text = "Sort: Active"
		FileManager.SortMode.ACTIVE:
			cur_sort = FileManager.SortMode.NAME
			$"%Sorter".text = "Sort: Name"
	_sort_mod_buttons()


func _on_sort_invert_toggled(toggled: bool):
	cur_sort_inverted = toggled
	_sort_mod_buttons()


func _on_fm_folder_updated(path: String) -> void:
	on_mod_folder_updated(path)


func on_mod_folder_updated(_path: String):
	var modGlobalPath = ProjectSettings.globalize_path(_path)
	if !ProjectSettings.load_resource_pack(modGlobalPath, true):
		return
	refresh_mod(_path)


func refresh_mod(_path):
	var gdunzip = load('res://modloader/gdunzip/gdunzip.gd').new()
	gdunzip.load(_path)
	var modHash = ModLoader._hash_file(_path)
	for modEntryPath in gdunzip.files:
		var modSubFolder = modEntryPath.rsplit('/')[0]
		var modEntryName = modEntryPath.get_file().to_lower()
		if modEntryName.begins_with('modmain') and modEntryName.ends_with('.gd'):
			var metaRes = ModLoader._checkMetadata(modSubFolder, gdunzip.files, modEntryPath)
			if metaRes != null:
				var mod_name = metaRes[1].name
				if mods.has(mod_name):
					continue
				var modInfo = [metaRes[0], modHash, metaRes[1]]
				modInfo[2].zip_path = _path
				ModLoader.zips_by_name[modInfo[2].name] = _path
				ModLoader.disabled_mod_names[modInfo[2].name] = true
				ModLoader.all_mods.append(modInfo)
				ModLoader.inactive_mods.append(modInfo)
				modInfo.remove(0)
				add_mod(modInfo)
				file_manager._refresh_lists_menu()
				_sort_mod_buttons()
				continue


func adjust_ui(is_mobile):
	$"%WorkshopUploader".visible = not is_mobile
	$"%WorkshopButton".visible = not is_mobile


func _open_mods_folder():
	OS.shell_open(file_manager.dir_path)

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

	#Add button container to $mods
	self.list_container.add_child(_container)
	# Generate tab container
	var info = generate_mod_menu(mod[1].friendly_name)
	self.info_container.add_child(info)

	#Connect button
	btn.connect("pressed", self, "_tab_clicked", [info, mod[1].zip_path])
	toggle.connect("toggled", self, "_on_toggle_pressed", [mod, toggle, btn])
	_set_toggle_state(true, mod, toggle, btn)

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

func _tab_clicked(node:Node, _zip_path:String):
	if current_mod != node:
		file_manager.cur_item_path = _zip_path
		show_menu(node)


# Signal handler for a human actually clicking a toggle. This is the
# only path that should persist anything — it updates the UI/mods dict
# AND saves the change to the currently selected list (or "unnamed" if
# none is selected).
func _on_toggle_pressed(_button_pressed: bool, _mod, _toggle, _button):
	_set_toggle_state(_button_pressed, _mod, _toggle, _button)
	var idx = file_manager.option_button.selected
	if idx >= 0 and idx < file_manager.loaded_lists.size():
		file_manager.save_current_list(file_manager.loaded_lists[idx].list_name)
	else:
		file_manager.save_current_list("")


# Pure UI/state sync — no saving, no calling back into the file manager.
# Safe to call from add_mod() (initial setup) and apply_new_list()
# (restoring saved state) without risk of feeding back into a save
# that re-triggers a restore that re-triggers apply_new_list again.
func _set_toggle_state(_button_pressed: bool, _mod, _toggle, _button):
	var mod_name = _mod[1].name
	mods[mod_name] = {
		"active": _button_pressed,
		"mod": _mod,
		"toggle": _toggle,
		"button": _button,
		"parent": _button.get_parent()
	}

	var is_mod_active = _mod in ModLoader.active_mods
	_button.add_color_override("font_color", Color("ff333b" if _button_pressed != is_mod_active else "ffffff"))

	_toggle.set_pressed_no_signal(_button_pressed)


func _sort_mod_buttons():
	var items := []
	for mod_entry in mods.values():
		items.append({
			"name": mod_entry.button.text,
			"active": mod_entry.active,
			"path": mod_entry.mod[1].zip_path,
			"parent": mod_entry.parent,
		})
	items = FileManager.sort_items(items, cur_sort, cur_sort_inverted)
	for i in range(items.size()):
		list_container.move_child(items[i].parent, i)


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


func get_current_list(_default = false) -> Dictionary:
	var _saved_active_list := []
	var _saved_inactive_list := []

	for mod_name in mods:
		if _default:
			_saved_active_list.append(mod_name)
		elif mods[mod_name].active:
			_saved_active_list.append(mod_name)
		else:
			_saved_inactive_list.append(mod_name)

	var _current_list = {"active": _saved_active_list, "inactive": _saved_inactive_list}
	return _current_list


func apply_new_list(list: Dictionary):
	for mod_name in mods:
		var entry = mods[mod_name]
		if mod_name in list.active:
			_set_toggle_state(true, entry.mod, entry.toggle, entry.button)
		elif mod_name in list.inactive:
			_set_toggle_state(false, entry.mod, entry.toggle, entry.button)


func get_listed(list: Dictionary) -> Array:
	var _items = []

	for mod_name in mods:
		var entry = mods[mod_name]
		if mod_name in list.active:
			_items.append(entry.mod[1].zip_path)

	return _items


# ---------------------------------------------------------------------------
# FileManagerInterface signal handlers - thin wrappers around the existing
# business logic above, replacing the old has_method()/call()-by-name wiring.
# ---------------------------------------------------------------------------

func _on_fm_get_data_requested(use_default: bool, result: Dictionary) -> void:
	result["data"] = get_current_list(use_default)


func _on_fm_apply_data_requested(data: Dictionary) -> void:
	apply_new_list(data)


func _on_fm_get_listed_requested(list_data: Dictionary, result: Dictionary) -> void:
	result["paths"] = PoolStringArray(get_listed(list_data))


func _on_apply_changes_pressed():
	get_tree().quit()
