extends VBoxContainer


signal file_saved

var data_source: Object
var get_data_method := "get_list_data" 
var apply_data_method := "apply_list_data"
var loaded_items: Array = []

# https://github.com/pattlebass/Godot-File-Picker
var android_picker

export var directory: String = "user://mods"
export var extensions: PoolStringArray = ["zip", "ymd"]
export var list_extension: String = ".ymdlist"
export var list_directory: String = "user://lists/mods"

onready var option_button = $"%OptionButton"
onready var list_edit = $"%ListEdit"



func _ready():
	$"%ImportFiles".connect("pressed", self, "_on_import_files_pressed")
	$"%SaveList".connect("pressed", self, "_on_save_list_pressed")
	$"%DeleteList".connect("pressed", self, "_on_delete_list_pressed")
	option_button.connect("item_selected", self, "_on_option_button_item_selected")
	list_edit.connect("text_entered", self, "_on_list_edit_text_entered")
	
	if OS.get_name() == "Android" and Engine.has_singleton("GodotFilePicker"):
		android_picker = Engine.get_singleton("GodotFilePicker")
		android_picker.connect("file_picked", self, "_on_android_file_picked", [directory, extensions])


func _on_import_files_pressed():
	if OS.get_name() == "Android":
		if android_picker:
			android_picker.openFilePicker("*/*")
		else:
			_report_from_directory()
	else:
		var gameInstallDirectory = OS.get_executable_path().get_base_dir()
		if OS.get_name() == "OSX":
			gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
		var modPathPrefix = gameInstallDirectory.plus_file("mods")
		select_file_from_directory(modPathPrefix, extensions)


func _on_android_file_picked(temp_path: String, mime_type: String, _directory: String, _extensions: PoolStringArray) -> void:
	save_file_to_directory(temp_path, _directory, _extensions)
	Directory.new().remove(temp_path)


# Android fallback on no plugin installed - VineRaio
func _report_from_directory() -> void:
	var found := _scan_directory_for_files(directory, extensions)
	if found.empty():
		$"%Printer".text = "No mod files found"
	else:
		$"%Printer".text = "Mods found: " + PoolStringArray(found).join(", ")


func _scan_directory_for_files(_directory: String, _extensions: PoolStringArray) -> Array:
	var results := []
	var dir = Directory.new()
	if dir.open(_directory) != OK:
		return results
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			for extension in _extensions:
				if file_name.get_extension().to_lower() == extension:
					results.append(file_name)
					break
		file_name = dir.get_next()
	dir.list_dir_end()
	return results


func select_file_from_directory(_directory: String, _extensions: PoolStringArray = []):
	var dialog := FileDialog.new()
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	var patterns := PoolStringArray()
	for extension in _extensions:
		patterns.append("*." + extension)
	dialog.filters = PoolStringArray([patterns.join(",") + " ; Your Only Move Is Hustle Files"])
	
	dialog.rect_min_size = Vector2(400, 200)
	dialog.current_dir = OS.get_environment("USERPROFILE") + "/Downloads"
	add_child(dialog)
	dialog.connect("file_selected", self, "save_file_to_directory", [_directory, _extensions])
	dialog.popup_centered()
	dialog.connect("popup_hide", dialog, "queue_free")


func save_file_to_directory(_path: String, _directory: String, _extensions: PoolStringArray) -> bool:
	var ext = _path.get_extension().to_lower()
	if not ext in _extensions:
		$"%Printer".text = "Failed to import file, it doesn't match the extensions: " + _extensions.join(", ")
		return false
	
	var dir = Directory.new()
	if not dir.dir_exists(_directory):
		var err = dir.make_dir_recursive(_directory)
	
		if err != OK:
			$"%Printer".text = "Failed to import file, the directory couldn't be created at:" + _directory + " . error code: " + str(err)
			return false
	
	var file_name = _path.get_file()
	var dest_path = _directory + "/" + file_name
	var err = dir.copy(_path, dest_path)
	
	if err == OK:
		if dir.file_exists(dest_path):
			$"%Printer".text = "File imported and verified: " + file_name
			emit_signal("file_saved", dest_path)
			return true
		else:
			$"%Printer".text = "Copy reported OK but file not found at destination"
			return false
	else:
		$"%Printer".text = "Failed to import file, error code: " + str(err)
		return false


func _on_save_list_pressed():
	save_current_list(list_edit.text)


func setup_lists(source: Object, get_method := "get_list_data", apply_method := "apply_list_data"):
	data_source = source
	get_data_method = get_method
	apply_data_method = apply_method
	
	_refresh_lists_menu()


func _refresh_lists_menu():
	var raw = load_all_lists()
	loaded_items = []
	option_button.clear()
	for item in raw:
		if item.get("list_name", "") == "_current_state" or item.get("list_name", "") == "_last_selected":
			continue
		loaded_items.append(item)
		option_button.add_item(item.get("list_name", "unnamed"))


func _on_option_button_item_selected(index):
	if loaded_items.size() > index:
		_apply_lists(loaded_items[index])


func refresh_applied_list():
	var f = File.new()
	if not f.file_exists(list_directory + "/_last_selected.ymdlist"):
		return
	f.open(list_directory + "/_last_selected.ymdlist", File.READ)
	var data = f.get_var()
	f.close()
	
	var _selected_list_name = data.get("selected_list_name", "")
	select_list_by_name(_selected_list_name)
	
	if loaded_items.size() > option_button.selected and option_button.selected != -1:
		_apply_lists(loaded_items[option_button.selected])


func _apply_lists(data: Dictionary):
	if data_source != null and data_source.has_method(apply_data_method):
		data_source.call(apply_data_method, data)
		save_list({"selected_list_name": data.get("list_name", "unnamed")}, "_last_selected")


func save_current_list(name_text: String) -> String:
	if data_source == null or !data_source.has_method(get_data_method):
		push_warning("no data_source / get method set")
		return ""
	var data: Dictionary = data_source.call(get_data_method)
	var clean_name = Utils.filter_filename(name_text)
	var saved_name = save_list(data, clean_name)
	save_list({"selected_list_name": saved_name}, "_last_selected")
	_refresh_lists_menu()
	select_list_by_name(saved_name)
	return saved_name


func select_list_by_name(list_name: String):
	for i in loaded_items.size():
		if loaded_items[i].get("list_name", "") == list_name:
			option_button.selected = i
			return


func delete_selected_list():
	var idx = option_button.selected
	if idx < 0 or idx >= loaded_items.size():
		return
	delete_list(loaded_items[idx].get("list_name", ""))
	_refresh_lists_menu()


func _on_list_edit_text_entered(new_text):
	if new_text != "_current_state" and new_text != "_last_selected":
		save_current_list(new_text)
	list_edit.clear()


func make_folder():
	var dir = Directory.new()
	if !dir.dir_exists(list_directory):
		dir.make_dir_recursive(list_directory)


func save_list(data: Dictionary, list_name: String) -> String:
	list_name = list_name.strip_edges()
	if list_name == "":
		list_name = "unnamed"
	make_folder()
	data = data.duplicate(true)
	data["list_name"] = list_name
	var file = File.new()
	file.open(list_directory + "/" + list_name + list_extension, File.WRITE)
	file.store_var(data, true)
	file.close()
	return list_name


func load_all_lists() -> Array:
	make_folder()
	var dir = Directory.new()
	var files = []
	var _directories = []
	var items = []
	dir.open(list_directory)
	dir.list_dir_begin(false, true)
	Global.add_dir_contents(dir, files, _directories, false, list_extension)
	for path in files:
		var file = File.new()
		file.open(path, File.READ)
		var data: Dictionary = file.get_var()
		items.append(data)
		file.close()
	return items


func _on_delete_list_pressed():
	delete_selected_list()


func delete_list(list_name: String):
	var dir = Directory.new()
	dir.remove(list_directory + "/" + list_name + list_extension)
