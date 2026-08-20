extends Window
class_name FileManager

const LIST_EXT_NAME: String = ".ymdlist"

# https://github.com/pattlebass/Godot-File-Picker
var android_picker

var data_source: Object
var get_data_method := "get_list_data"
var apply_data_method := "apply_list_data"
var folder_updated_method := "folder_updated_method"

var loaded_lists := []
var cur_item_path := ""
var cur_list_name := ""

var dir_name := "mods"
var ext_names := [".zip", ".ymd"]
var dir_path := "user://mods"
var list_dir_path := "user://lists/mods"

var ext_close_button: Object
var ext_open_button: Object

var sort_method := ""

var files_to_delete = []

onready var option_button = $"%OptionButton"
onready var list_edit = $"%ListEdit"


func _ready():
	$"%Close".connect("pressed", self, "_on_close_pressed")
	$"%ImportFiles".connect("pressed", self, "_on_import_files_pressed")
	$"%SaveList".connect("pressed", self, "_on_save_list_pressed")
	$"%ExportFile".connect("pressed", self, "_on_export_file_pressed")
	$"%ExportList".connect("pressed", self, "_on_export_list_pressed")
	$"%ExportListed".connect("pressed", self, "_on_export_listed_pressed")
	$"%ExportFolder".connect("pressed", self, "_on_export_folder_pressed")
	$"%DeleteFile".connect("pressed", self, "_on_delete_file_pressed")
	$"%DeleteList".connect("pressed", self, "_on_delete_list_pressed")
	$"%DeleteListed".connect("pressed", self, "_on_delete_listed_pressed")
	$"%DeleteFolder".connect("pressed", self, "_on_delete_folder_pressed")

	option_button.connect("item_selected", self, "_on_option_button_item_selected")
	list_edit.connect("text_entered", self, "_on_list_edit_text_entered")

	if OS.get_name() == "Android" and Engine.has_singleton("GodotFilePicker"):
		android_picker = Engine.get_singleton("GodotFilePicker")
		android_picker.connect("file_picked", self, "_on_android_file_picked", [dir_name, ext_names])


func setup(
	_dir_name: String,
	_ext_names: PoolStringArray,
	source: Object,
	get_method: String,
	apply_method: String,
	folder_method: String,
	_sort_method: String,
	_ext_close_button: Object,
	_ext_open_button: Object,
	_use_game_folder = false
):
	dir_name = _dir_name
	ext_names = _ext_names
	
	if _use_game_folder:
		var gameInstallDirectory = OS.get_executable_path().get_base_dir()
		if OS.get_name() == "OSX":
			gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
		dir_path = gameInstallDirectory.plus_file(_dir_name)
	else:
		dir_path = "user://mods".plus_file(_dir_name)
	
	list_dir_path = "user://lists".plus_file(_dir_name)
	
	data_source = source
	get_data_method = get_method
	apply_data_method = apply_method
	folder_updated_method = folder_method
	sort_method = _sort_method
	
	if ext_close_button:
		if ext_close_button.is_connected("pressed", self, "_on_close_pressed"):
			ext_close_button.disconnect("pressed", self, "_on_close_pressed")
	
	if ext_open_button:
		if ext_open_button.is_connected("pressed", self, "_on_open_pressed"):
			ext_open_button.disconnect("pressed", self, "_on_open_pressed")
	
	ext_close_button = _ext_close_button
	ext_open_button = _ext_open_button
	
	ext_close_button.connect("pressed", self, "_on_close_pressed")
	ext_open_button.connect("pressed", self, "_on_open_pressed")
	
	_refresh_lists_menu()


func sort_data(data: Array) -> Array:
	if data_source == null:
		return data
	
	if sort_method == "":
		return data
	
	if not data_source.has_method(sort_method):
		push_warning("Sort method not found: " + sort_method)
		return data
	
	data.sort_custom(data_source, sort_method)
	return data


func _on_close_pressed():
	hide()


func _on_open_pressed():
	show()


func _on_import_files_pressed():
	if OS.get_name() == "Android":
		if android_picker:
			android_picker.openFilePicker("*/*")
		else:
			_report_from_directory()
	else:
		select_file_from_directory(dir_path, ext_names)


func _on_export_file_pressed():
	if cur_item_path == "":
		return
	var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	copy_file_to_directory(cur_item_path, downloads_dir, ext_names, false)


func _on_android_file_picked(
	temp_path: String,
	mime_type: String,
	_directory: String,
	_extensions: PoolStringArray
) -> void:
	copy_file_to_directory(temp_path, _directory, _extensions)
	Directory.new().remove(temp_path)


func _report_from_directory() -> void:
	var found := _scan_directory_for_files(dir_name, ext_names)
	
	if found.empty():
		$"%Printer".text = "No mod files found"
	else:
		$"%Printer".text = "Mods found: " + PoolStringArray(found).join(", ")


func _scan_directory_for_files(
	_directory: String,
	_extensions: PoolStringArray
) -> Array:
	var results := []
	var dir = Directory.new()
	
	if dir.open(_directory) != OK:
		return results
	
	dir.list_dir_begin(true, true)
	
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			for extension in _extensions:
				if "." + file_name.get_extension().to_lower() == extension:
					results.append(file_name)
					break
	
	file_name = dir.get_next()
	dir.list_dir_end()
	
	return results


func select_file_from_directory(
	_directory: String,
	_extensions: PoolStringArray = []
):
	var dialog := FileDialog.new()
	
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	var fixed_exts := PoolStringArray()
	for extension in _extensions:
		fixed_exts.append("*" + extension)
	dialog.filters = PoolStringArray([fixed_exts.join(",") + " ; Your Only Move Is Hustle Files"])
	
	dialog.rect_min_size = Vector2(400, 200)
	dialog.current_dir = OS.get_environment("USERPROFILE") + "/Downloads"
	
	add_child(dialog)
	
	dialog.connect("file_selected", self, "copy_file_to_directory", [_directory, _extensions])
	
	dialog.popup_centered()
	dialog.connect("popup_hide", dialog, "queue_free")


func copy_file_to_directory(
	_path: String,
	_directory: String,
	_extensions: PoolStringArray,
	_update_folder = true
) -> bool:
	var ext = "." + _path.get_extension().to_lower()
	
	if not ext in _extensions:
		$"%Printer".text = (
			"Failed to copy file, it doesn't match the extensions: "
			+ _extensions.join(", ")
		)
		return false
	
	var dir = Directory.new()
	
	if not dir.dir_exists(_directory):
		var err = dir.make_dir_recursive(_directory)
		
		if err != OK:
			$"%Printer".text = (
				"Failed to copy file, the dir_name couldn't be created at: "
				+ _directory
				+ " . error code: "
				+ str(err)
			)
			return false
	
	var file_name = _path.get_file()
	var dest_path = _directory + "/" + file_name
	var err = dir.copy(_path, dest_path)
	
	if err == OK:
		if dir.file_exists(dest_path):
			$"%Printer".text = "File copied and verified: " + dest_path
			if (_update_folder and data_source != null and data_source.has_method(folder_updated_method)):
				data_source.call(folder_updated_method, dest_path, true)
			return true
		else:
			$"%Printer".text = ("Copy reported OK but file not found at destination")
			return false
	else:
		$"%Printer".text = ("Failed to copy file, error code: " + str(err))
		return false


func _on_save_list_pressed():
	save_current_list(list_edit.text)


func _refresh_lists_menu():
	var raw = load_all_lists()
	
	loaded_lists = []
	option_button.clear()
	
	for item in raw:
		if (item.get("list_name", "") == "_current_state" or item.get("list_name", "") == "_last_selected"):
			continue
		
		loaded_lists.append(item)
		option_button.add_item(item.get("list_name", "unnamed"))
	
	_restore_current_state()
	_highlight_last_selected()


func _restore_current_state():
	var data = _load_special("_current_state")
	if data.empty():
		return
	if data_source != null and data_source.has_method(apply_data_method):
		data_source.call(apply_data_method, data)


func _highlight_last_selected():
	var data = _load_special("_last_selected")
	cur_list_name = data.get("selected_list_name", "")
	for i in loaded_lists.size():
		if loaded_lists[i].get("list_name", "") == cur_list_name:
			option_button.selected = i
			return
	option_button.selected = -1


func _load_special(name: String) -> Dictionary:
	var f = File.new()
	var path = list_dir_path.plus_file(name) + LIST_EXT_NAME
	if not f.file_exists(path):
		return {}
	f.open(path, File.READ)
	var data = f.get_var()
	f.close()
	return data


func _on_option_button_item_selected(index):
	if loaded_lists.size() > index:
		_apply_lists(loaded_lists[index])


func _apply_lists(data: Dictionary):
	if data_source != null and data_source.has_method(apply_data_method):
		data_source.call(apply_data_method, data)
	save_list(data, "_current_state")
	save_list(
		{"selected_list_name": data.get("list_name", "unnamed")},
		"_last_selected"
	)


func save_current_list(name_text: String) -> String:
	if data_source == null or not data_source.has_method(get_data_method):
		push_warning("no data_source / get method set")
		return ""
	
	var data: Dictionary = data_source.call(get_data_method)
	var clean_name = Utils.filter_filename(name_text)
	var saved_name = save_list(data, clean_name)
	_refresh_lists_menu()
	select_list_by_name(saved_name)
	return saved_name


func select_list_by_name(list_name: String):
	for i in loaded_lists.size():
		if loaded_lists[i].get("list_name", "") == list_name:
			option_button.selected = i
			_on_option_button_item_selected(i)
			return


func _on_list_edit_text_entered(new_text):
	if (
		new_text != "_current_state"
		and new_text != "_last_selected"
	):
		save_current_list(new_text)
	list_edit.clear()


func make_folder():
	var dir = Directory.new()
	if not dir.dir_exists(list_dir_path):
		dir.make_dir_recursive(list_dir_path)


func save_list(data: Dictionary, list_name: String) -> String:
	list_name = list_name.strip_edges()
	if list_name == "":
		list_name = "unnamed"
	make_folder()
	data = data.duplicate(true)
	data["list_name"] = list_name
	var file = File.new()
	file.open(
		list_dir_path.plus_file(list_name) + LIST_EXT_NAME,
		File.WRITE
	)
	file.store_var(data, true)
	file.close()
	return list_name


func load_all_lists() -> Array:
	make_folder()
	var dir = Directory.new()
	var files = []
	var _directories = []
	var items = []
	dir.open(list_dir_path)
	dir.list_dir_begin(false, true)
	Global.add_dir_contents(dir, files, _directories, false, LIST_EXT_NAME)
	for path in files:
		var file = File.new()
		file.open(path, File.READ)
		var data: Dictionary = file.get_var()
		items.append(data)
		file.close()
	dir.list_dir_end()
	return items


func _on_delete_list_pressed():
	if cur_list_name == "":
		return
	var dir = Directory.new()
	dir.remove(list_dir_path.plus_file(cur_list_name) + LIST_EXT_NAME)
	_refresh_lists_menu()


func _on_export_list_pressed():
	if cur_list_name == "":
		return
	var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	copy_file_to_directory(
		list_dir_path.plus_file(cur_list_name) + ".ymdlist",
		downloads_dir,
		[LIST_EXT_NAME],
		false
	)


func _on_delete_file_pressed():
	if cur_item_path == "":
		return
	_mark_for_deletion(cur_item_path)
	get_tree().quit()


func _mark_for_deletion(path: String):
	var data = []
	var file = File.new()
	var save_path = "user://lists/files_to_delete.ymdlist"
	if file.file_exists(save_path):
		file.open(save_path, File.READ)
		data = file.get_var()
		data.append(path)
	file.close()
	
	var file2 = File.new()
	file2.open("user://lists/files_to_delete.ymdlist",File.WRITE)
	file2.store_var(data, true)
	file2.close()
