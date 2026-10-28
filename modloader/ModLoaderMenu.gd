extends Window


signal uploader_clicked()

const MODIO_BROWSER_SCENE := preload("res://modloader/modio/ModIOBrowser.tscn")
const MODIO_UPLOADER_SCENE := preload("res://modloader/modio/ModIOUploader.tscn")
const GDUNZIP := preload("res://modloader/gdunzip/gdunzip.gd")

var ModOptions
var current_mod = null
var mod_tabs:Dictionary = {}
var mods: Dictionary = {}
var userdata := {}
var late_inited = false
var needs_to_save = false

var cur_sort = FileManager.SortMode.DATE
var cur_sort_inverted := false

var fm_window: Control

var modio_browser = null
var modio_uploaders := {}
var credits = null

onready var list_container = $"%Mods"
onready var info_container = $"%ModInfoContainer"
onready var file_manager: FileManagerInterface = $"%FileManagerInterface"
onready var modio_layer: CanvasLayer = get_parent().get_node("%ModIOLayer")


# Called when the node enters the scene tree for the first time.
func _ready():
	#ModOptions = load("res://modloader/ModOptions.gd").new()
	#ModOptions.menu = self
	#get_tree().get_current_scene().call_deferred("add_child", ModOptions, true)
	$"%Close".connect("pressed", self, "_close_clicked")
	$"%ModsLocation".connect("pressed", self, "_open_mods_folder")
	$"%PlayerDataFolder".connect("pressed", self, "_open_mods_folder")
	$"%ModCredits".connect("pressed", self, "_credits_clicked")
	$"%WorkshopUploader".connect("pressed", self, "_uploader_clicked")
	$"%WorkshopButton".connect("pressed", self, "_workshop_clicked")
	$"%ApplyChanges".connect("pressed", self, "_on_apply_changes_pressed")
	$"%Sorter".connect("pressed", self, "_on_sorter_pressed")
	$"%SortInvert".connect("toggled", self, "_on_sort_invert_toggled")
	$"%AllOnButton".connect("pressed", self, "_on_mod_all_toggled", [true])
	$"%AllOffButton".connect("pressed", self, "_on_mod_all_toggled", [false])
	$"%OpenFileManager".connect("toggled", self, "_open_file_manager")

	Global.connect("mobile_ui_changed", self, "adjust_ui")
	adjust_ui(Global.mobile_ui)
	UIManager.register_menu(self, [
		$VBoxContainer/TitleBar/Close,
		$VBoxContainer/TitleBar/HBoxContainer/ApplyChanges,
		$VBoxContainer/TitleBar/HBoxContainer/OpenFileManager,
		$VBoxContainer/TitleBar/HBoxContainer/ModsLocation,
		$VBoxContainer/FMRow,
		$VBoxContainer/FMRow/Sorter,
		$VBoxContainer/FMRow/SortInvert,
		$VBoxContainer/FMRow/AllOnButton,
		$VBoxContainer/FMRow/AllOffButton,
		$VBoxContainer/Panel/HBoxContainer/ModCredits,
		$VBoxContainer/Panel/HBoxContainer/WorkshopButton,
		$VBoxContainer/Panel/HBoxContainer/WorkshopUploader,
		$VBoxContainer/Panel/HBoxContainer/PlayerDataFolder,
	])

	_setup_file_manager()


func _setup_file_manager() -> void:
	file_manager.connect("get_data_requested", self, "_on_fm_get_data_requested")
	file_manager.connect("apply_data_requested", self, "_on_fm_apply_data_requested")
	file_manager.connect("get_listed_requested", self, "_on_fm_get_listed_requested")
	file_manager.connect("folder_updated", self, "_on_fm_folder_updated")
	
	# On desktop mods live next to the executable (use_game_folder=true),
	# which matches what _loadMods() uses. On Android the APK dir is
	# read-only so we must write to user://mods instead.
	file_manager.setup("mods", PoolStringArray([".zip", ".ymhpack"]),
		not Global.is_mobile_device, true)
	
	# Show the sorter/invert bar only while the FM window is open.
	fm_window = file_manager.get_node("%Window")
	fm_window.connect("visibility_changed", self, "_on_fm_window_visibility_changed")
	$"%FMRow".connect("visibility_changed", self, "_on_fm_row_visibility_changed")
	
	# Wire the FM's own Close so one press closes both windows.
	$"%Close".connect("pressed", file_manager, "_on_close_pressed")


func _loadMods():
	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
	var modPathPrefix = gameInstallDirectory.plus_file("mods")
	_load_mods_in_folder(modPathPrefix)

	var workshop = SteamWorkshop.new()
	if SteamHustle.STARTED and SteamHustle.WORKSHOP_ENABLED:
		for item in Steam.getSubscribedItems():
			var info = workshop.get_item_install_info(item)
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
	if dir.list_dir_begin(true, true) != OK:
		return

	var _modZipFiles = []

	while true:
		var fileName = dir.get_next()
		if fileName == '':
			break
		if dir.current_is_dir():
			continue
		var modFSPath: String = modPathPrefix.plus_file(fileName)
		var extension = modFSPath.get_extension().to_lower()
		if zip_only and extension != "zip":
			continue
		if extension == "zip":
			_modZipFiles.append(modFSPath)
			continue
		if extension == "ymhpack":
			continue
		var modGlobalPath = ProjectSettings.globalize_path(modFSPath)
		if !ProjectSettings.load_resource_pack(modGlobalPath, true):
			continue
		_modZipFiles.append(modFSPath)

	# MOUNT ZIP FILES FIRST (for metadata reading)
	for mod_path in _modZipFiles:
		if mod_path.get_extension().to_lower() == "zip":
			var modGlobalPath = ProjectSettings.globalize_path(mod_path)
			ProjectSettings.load_resource_pack(modGlobalPath, true)

	# THEN refresh mods (reads from mounted packs)
	for mod_path in _modZipFiles:
		refresh_mod(mod_path)


func _open_file_manager(pressed: bool):
	if pressed:
		file_manager._on_open_pressed()
	else:
		file_manager._on_close_pressed()


# visibility_changed fires with no args in Godot 3.x, so read the window
# state here instead of taking a parameter.
func _on_fm_window_visibility_changed() -> void:
	var visible = fm_window.visible
	$"%OpenFileManager".set_pressed_no_signal(visible)
	$"%FMRow".visible = visible
	_reapply_ui()


func _on_fm_row_visibility_changed() -> void:
	_reapply_ui()


func _reapply_ui() -> void:
	if Global.mobile_ui:
		UIManager.reapply_menu(self)


func _on_sorter_pressed():
	cur_sort = FileManager.next_sort_mode(cur_sort)
	$"%Sorter".text = FileManager.sort_label(cur_sort)
	_sort_mod_buttons()


func _on_sort_invert_toggled(toggled: bool):
	cur_sort_inverted = toggled
	_sort_mod_buttons()


func _on_fm_folder_updated(path: String) -> void:
	on_mod_folder_updated(path)


func on_mod_folder_updated(_path: String):
	refresh_mod(_path)


func refresh_mod(_path):
	if _path.get_extension().to_lower() != "zip":
		return

	var gdunzip = GDUNZIP.new()
	gdunzip.load(_path)
	var modHash = ModLoader._hash_file(_path)

	for modEntryPath in gdunzip.files:
		var modSubFolder = modEntryPath.rsplit('/')[0]
		var modEntryName = modEntryPath.get_file().to_lower()
		if modEntryName.begins_with('modmain') and modEntryName.ends_with('.gd'):
			var modMetadataPath = "res://" + modSubFolder + "/_metadata"
			var metadata = ModLoader._readMetadata(modMetadataPath)
			if metadata == null:
				print("No metadata in mod: " + modSubFolder)
				continue
			var check = ModLoader._verifyMetadata(metadata)
			if check != null:
				print("Metadata error: " + check)
				continue

			var mod_name = metadata.name

			# CHECK FOR MERGED MODS - skip if integrated into base game
			if ModLoader.knownMergedModNames.has(mod_name):
				print("Skipping merged mod: " + mod_name + " (integrated into base game)")
				continue

			# Don't re-add mods already loaded by ModLoader during boot
			if mods.has(mod_name):
				continue
			if mod_name in ModLoader.zips_by_name:
				# Mod already known to ModLoader, sync UI state
				if not mods.has(mod_name):
					var modInfo = [modHash, metadata]
					metadata.zip_path = _path
					ModLoader.zips_by_name[mod_name] = _path
					ModLoader.disabled_mod_names[mod_name] = true
					ModLoader.all_mods.append(modInfo)
					ModLoader.inactive_mods.append(modInfo)
					add_mod(modInfo)
					file_manager._refresh_lists_menu()
					_sort_mod_buttons()
				continue

			var modInfo = [modHash, metadata]
			metadata.zip_path = _path
			ModLoader.zips_by_name[mod_name] = _path
			ModLoader.disabled_mod_names[mod_name] = true
			ModLoader.all_mods.append(modInfo)
			ModLoader.inactive_mods.append(modInfo)
			add_mod(modInfo)
			file_manager._refresh_lists_menu()
			_sort_mod_buttons()
			break


func adjust_ui(is_mobile):
	$"%WorkshopUploader".visible = not Global.is_mobile_device
	$"%WorkshopButton".visible = not Global.is_mobile_device
	$"%ModsLocation".visible = not Global.is_mobile_device
	$"%PlayerDataFolder".visible = Global.is_mobile_device


func _open_mods_folder():
	if OS.get_name() == "Android":
		var folder := OS.get_user_data_dir()
		OS.set_clipboard(folder)
		var dialog := AcceptDialog.new()
		dialog.theme = preload("res://theme.tres")
		dialog.window_title = "Player Data Folder"
		dialog.dialog_text = "Copied to clipboard:\n" + folder + "\n\nPaste this path into your file manager to add or remove mods, styles, and other data. Changes to mod files are applied the next time you start the game."
		add_child(dialog)
		dialog.connect("popup_hide", dialog, "queue_free")
		dialog.popup_centered()
		return
	OS.shell_open(file_manager.dir_path)

func _uploader_clicked():
	hide()
	emit_signal("uploader_clicked")


func _workshop_upload_mod_clicked():
	if is_instance_valid(modio_browser):
		modio_browser.hide()
	_uploader_clicked()


func _workshop_clicked():
#	hide()
	Steam.activateGameOverlayToWebPage("https://steamcommunity.com/app/2212330/workshop/")
#	emit_signal("uploader_clicked")

func _modio_clicked():
	_hide_modio_uploaders()
	if modio_browser == null or not is_instance_valid(modio_browser):
		modio_browser = MODIO_BROWSER_SCENE.instance()
		modio_browser.menu = self
		modio_browser.connect("upload_mod_requested", self, "_modio_upload_mod_clicked")
		modio_browser.connect("upload_guide_requested", self, "_modio_upload_guide_clicked")
		modio_browser.connect("upload_collection_requested", self, "_modio_upload_collection_clicked")
		modio_browser.connect("upload_workshop_requested", self, "_workshop_upload_mod_clicked")
		modio_browser.connect("closed", self, "_modio_closed")
		modio_layer.add_child(modio_browser)
	get_parent().hide_main_menu()
	modio_browser.open()

func _modio_closed():
	get_parent().show_main_menu()

func _hide_modio_uploaders():
	for window in modio_uploaders.values():
		if is_instance_valid(window):
			window.close_menu()

func _modio_upload_mod_clicked():
	_open_modio_uploader("mod")

func _modio_upload_guide_clicked():
	_open_modio_uploader("guide")

func _modio_upload_collection_clicked():
	_open_modio_uploader("collection")

func _open_modio_uploader(kind: String) -> void:
	_hide_modio_uploaders()
	var window = modio_uploaders.get(kind)
	if window == null:
		window = MODIO_UPLOADER_SCENE.instance()
		window.kind = kind
		window.connect("upload_complete", self, "_on_modio_upload_complete")
		modio_layer.add_child(window)
		modio_uploaders[kind] = window
	window.open()

func _on_modio_upload_complete():
	file_manager._refresh_lists_menu()
	if is_instance_valid(modio_browser):
		modio_browser.reload_current()

func remove_mod_by_zip(zip_path: String) -> void:
	if zip_path == "":
		return
	var target_name = null
	for mod_name in mods:
		var list_entry = mods[mod_name]
		var list_metadata = _mod_metadata(list_entry.mod)
		if list_metadata != null and list_metadata.get("zip_path", "") == zip_path:
			target_name = mod_name
			break
	if target_name == null:
		return
	var entry = mods[target_name]

	for mod_list in [ModLoader.all_mods, ModLoader.active_mods, ModLoader.inactive_mods]:
		var i = mod_list.size() - 1
		while i >= 0:
			var list_metadata = _mod_metadata(mod_list[i])
			if list_metadata != null and list_metadata.get("zip_path", "") == zip_path:
				mod_list.remove(i)
				ModLoader.disabled_mod_names.erase(list_metadata.get("name", ""))
			i -= 1
	for mod_name in ModLoader.zips_by_name.keys():
		if ModLoader.zips_by_name[mod_name] == zip_path:
			ModLoader.zips_by_name.erase(mod_name)

	if current_mod != null and is_instance_valid(current_mod) and current_mod.name == entry.button.text:
		current_mod.hide()
		current_mod = null
	for tab in info_container.get_children():
		if tab.name == entry.button.text:
			info_container.remove_child(tab)
			tab.queue_free()
	entry.parent.queue_free()
	mods.erase(target_name)
	file_manager._refresh_lists_menu()

func _mod_metadata(mod_info):
	if typeof(mod_info) != TYPE_ARRAY:
		return null
	if mod_info.size() > 1 and typeof(mod_info[1]) == TYPE_DICTIONARY:
		return mod_info[1]
	if mod_info.size() > 2 and typeof(mod_info[2]) == TYPE_DICTIONARY:
		return mod_info[2]
	return null

func _credits_clicked():
	credits.show()
	credits.raise()

func _close_clicked():
	hide()
	if current_mod:
		current_mod.hide()

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
	UIManager.register_menu(self, [_container, btn, toggle])
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
	if not mod[1].requires.empty():
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

func _tab_clicked(node:Node, _zip_path:String = ""):
	file_manager.cur_item_path = _zip_path
	if current_mod != node:
		show_menu(node)


# User clicked a toggle - update state and save to the current list.
func _on_toggle_pressed(_button_pressed: bool, _mod, _toggle, _button):
	_set_toggle_state(_button_pressed, _mod, _toggle, _button)
	file_manager.persist_selected_list()


# Pure UI/state sync - doesn't save, and is safe to call from add_mod() and
# apply_new_list() without feeding back into a save.
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


# "all on" / "all off" - flips every mod toggle at once, saves like above.
func _on_mod_all_toggled(on: bool) -> void:
	for mod_name in mods:
		var entry = mods[mod_name]
		_set_toggle_state(on, entry.mod, entry.toggle, entry.button)
	_sort_mod_buttons()
	file_manager.persist_selected_list()


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


# Save config dict of all mods with their active states into the file manager.
func get_current_list() -> Dictionary:
	var result := {}
	var active := []
	var inactive := []
	for mod in mods:
		if mods[mod].active:
			active.append(mods[mod].mod[1].name)
		else:
			inactive.append(mods[mod].mod[1].name)
	result["active"] = active
	result["inactive"] = inactive
	return result


# Apply the given list of mod names to the on/off mods dict and each toggle.
func apply_new_list(data: Dictionary) -> void:
	var active: Array = data.get("active", [])
	var inactive: Array = data.get("inactive", [])
	for mod_name in mods:
		var entry = mods[mod_name]
		var on = (mod_name in active) or (not mod_name in inactive)
		_set_toggle_state(on, entry.mod, entry.toggle, entry.button)
	_sort_mod_buttons()


# Turn a saved list into a pool of exact file paths (for Export/Delete).
func get_listed(list_data: Dictionary) -> PoolStringArray:
	var active: Array = list_data.get("active", [])
	var result := PoolStringArray()
	for mod_name in active:
		if mod_name in mods:
			result.append(mods[mod_name].mod[1].zip_path)
	return result


# FM asked for the current on/off state to save.
func _on_fm_get_data_requested(use_default, result) -> void:
	result["data"] = get_current_list()


# FM asks us to apply a stored list to the toggles.
func _on_fm_apply_data_requested(data) -> void:
	apply_new_list(data)


# FM asks which files belong to a list it's about to Export/Delete.
func _on_fm_get_listed_requested(list_data, result) -> void:
	result["paths"] = get_listed(list_data)


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


func _on_apply_changes_pressed():
	get_tree().quit()
