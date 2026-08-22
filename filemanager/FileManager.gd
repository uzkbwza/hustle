extends CanvasLayer
class_name FileManagement

# VineRaio's magnum ops, might use it even on my own game in the future! :3c

const LIST_EXT_NAME: String = ".ymhlist"

# https://github.com/pattlebass/Godot-File-Picker
var android_picker

var data_source: Object
var get_data_method := "get_list_data"
var apply_data_method := "apply_list_data"
var get_listed_method := "get_listed_method"
var folder_updated_method := "folder_updated_method"

var loaded_lists := []
var cur_item_path := ""
var cur_list_name := ""

var dir_name := "mods"
var ext_names := [".zip", ".ymhpack"]
var dir_path := "user://mods"
var list_dir_path := "user://lists/mods"

var ext_close_button: Object
var ext_open_button: Object

var sort_method := ""

var files_to_delete = []

onready var option_button = $"%OptionButton"
onready var list_edit = $"%ListEdit"


func _ready():
	$"%Window".hide()
	
	if Global.is_mobile_device:
		$"%ExportFileCustom".hide()
	
	if OS.get_name() == "Windows":
		register_file_associations()
	
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg.get_extension().to_lower() == "ymhpack":
			_import_ymhpack(arg)
	
	_check_ymhpack_inbox()
	
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
	$"%ExportFileCustom".connect("pressed", self, "_on_export_file_custom_pressed")

	option_button.connect("item_selected", self, "_on_option_button_item_selected")
	list_edit.connect("text_entered", self, "_on_list_edit_text_entered")

	if OS.get_name() == "Android" and Engine.has_singleton("GodotFilePicker"):
		android_picker = Engine.get_singleton("GodotFilePicker")
		android_picker.connect("file_picked", self, "_on_android_file_picked", [dir_path, ext_names])


func _on_export_file_custom_pressed():
	var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	select_file_from_directory([downloads_dir], [], FileDialog.ACCESS_USERDATA, "_on_custom_file_picked_for_export")


func _on_custom_file_picked_for_export(path: String, destination_dir: String):
	print(path)
	_export_ymhpack(PoolStringArray([path]), destination_dir)


func register_file_associations():
	# commented out for now, may enable later
#	if Global.registered_ymhpack:
#		return
	
	var exe_path = OS.get_executable_path().replace("/", "\\")
	
	var commands = [
		["add", "HKCU\\Software\\Classes\\.ymhpack", "/ve", "/d", "YourOnlyMoveIsHustlePack", "/f"],
		["add", "HKCU\\Software\\Classes\\YourOnlyMoveIsHustlePack", "/ve", "/d", "YourOnlyMoveIsHustlePack", "/f"],
		["add", "HKCU\\Software\\Classes\\YourOnlyMoveIsHustlePack\\shell\\open\\command", "/ve", "/d", "\"" + exe_path + "\" \"%1\"", "/f"],
		["add", "HKCU\\Software\\Classes\\YourOnlyMoveIsHustlePack\\DefaultIcon", "/ve", "/d", exe_path + ",0", "/f"],
	]
	
	for cmd in commands:
		OS.execute("reg", cmd, true)
	
	OS.execute("cmd", ["/c", "assoc", ".ymhpack"], false)
	
	Global.registered_ymhpack = true
	Global.save_options_after_change("registered_ymhpack", true)


func _notification(what):
	if Global.is_mobile_device and what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		_check_ymhpack_inbox()

func _check_ymhpack_inbox():
	var inbox = "user://ymhpack"
	var dir = Directory.new()
	if dir.open(inbox) == OK:
		dir.list_dir_begin(true, true)
		var f = dir.get_next()
		while f != "":
			if f.get_extension().to_lower() == "ymhpack":
				if _import_ymhpack(inbox + "/" + f):
					dir.remove(f)
			f = dir.get_next()
		dir.list_dir_end()


func _export_ymhpack(paths: PoolStringArray, destination_dir: String, package_name: String = "") -> bool:
	if paths.empty():
		$"%Printer".text = "Failed to export, no files given"
		return false
	
	var dir = Directory.new()
	if not dir.dir_exists(destination_dir):
		var mkerr = dir.make_dir_recursive(destination_dir)
		if mkerr != OK:
			$"%Printer".text = "Failed to export, couldn't create dir: " + destination_dir
			return false
	
	var entries := []
	
	for path in paths:
		var src_check = File.new()
		if not src_check.file_exists(path):
			$"%Printer".text = "Failed to export, file does not exist: " + path
			return false
		
		var payload_file = File.new()
		var read_err = payload_file.open(path, File.READ)
		if read_err != OK:
			$"%Printer".text = "Failed to export, couldn't read file: " + path
			return false
		
		var payload_bytes = payload_file.get_buffer(payload_file.get_len())
		payload_file.close()
		
		var entry := {
			"directory": path.get_base_dir(),
			"file_name": path.get_file(),
			"payload": payload_bytes,
		}
		entries.append(entry)
	
	var final_name = package_name
	if final_name.strip_edges() == "":
		final_name = paths[0].get_file().get_basename()
	var final_path = destination_dir.plus_file(final_name + ".ymhpack")
	
	var package := {"entries": entries}
	
	var out_file = File.new()
	var werr = out_file.open(final_path, File.WRITE)
	if werr != OK:
		$"%Printer".text = "Failed to export, couldn't write package, error code: " + str(werr)
		return false
	
	out_file.store_var(package, true)
	out_file.close()
	
	$"%Printer".text = "Exported " + str(entries.size()) + " file(s) to: " + final_path
	return true


func _import_ymhpack(path: String) -> bool:
	var f = File.new()
	if not f.file_exists(path):
		$"%Printer".text = "Package not found: " + path
		return false
	
	var open_err = f.open(path, File.READ)
	if open_err != OK:
		$"%Printer".text = "Failed to open package, error code: " + str(open_err)
		return false
	
	var package = f.get_var(true)
	f.close()
	
	if typeof(package) != TYPE_DICTIONARY or not package.has("entries"):
		$"%Printer".text = "Package is invalid: " + path
		return false
	
	var entries = package.get("entries", [])
	if typeof(entries) != TYPE_ARRAY or entries.empty():
		$"%Printer".text = "Package has no files: " + path
		return false
	
	var imported_count := 0
	
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		
		var dest_dir = entry.get("directory", "")
		var original_name = entry.get("file_name", "")
		var payload_bytes = entry.get("payload", null)
		
		if original_name == "" or payload_bytes == null:
			continue
		
		if dest_dir == "":
			$"%Printer".text = "Skipped file with unknown destination: " + original_name
			continue
		
		#quick fragile fix
		if "mods" in dest_dir and Global.is_mobile_device:
			dest_dir = "user://mods"
		
		var dir = Directory.new()
		if not dir.dir_exists(dest_dir):
			var mkerr = dir.make_dir_recursive(dest_dir)
			if mkerr != OK:
				$"%Printer".text = "Failed to import, couldn't create dir: " + dest_dir
				continue
		
		var dest_path = dest_dir.plus_file(original_name)
		var out_file = File.new()
		var werr = out_file.open(dest_path, File.WRITE)
		if werr != OK:
			$"%Printer".text = "Failed to import, couldn't write file: " + dest_path
			continue
		
		out_file.store_buffer(payload_bytes)
		out_file.close()
		
		if data_source != null and data_source.has_method(folder_updated_method):
			data_source.call(folder_updated_method, dest_path, true)
		imported_count += 1
	
	if imported_count == 0:
		$"%Printer".text = "Package imported nothing: " + path
		return false
	
	$"%Printer".text = "Package imported " + str(imported_count) + " file(s): " + path
	
	return true


func _on_visibility_changed():
	if not data_source.visible:
		data_source = null


func setup(
	_dir_name: String,
	_ext_names: PoolStringArray,
	source: Object,
	get_method: String,
	apply_method: String,
	folder_method: String,
	_get_listed_method: String,
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
	get_listed_method = _get_listed_method
	sort_method = _sort_method
	
	data_source.connect("visibility_changed", self, "_on_visibility_changed")
	
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
	$"%Window".show()


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
	$"%Window".hide()


func _on_open_pressed():
	$"%Window".show()


func _on_import_files_pressed():
	if OS.get_name() == "Android":
		if android_picker:
			android_picker.openFilePicker("*/*")
		else:
			_report_from_directory()
	else:
		select_file_from_directory([dir_path, ext_names], ext_names)


func _on_export_file_pressed():
	if cur_item_path == "":
		return
	var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	_export_ymhpack(PoolStringArray([cur_item_path]), downloads_dir)


func _on_export_listed_pressed():
	var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	for i in loaded_lists.size():
		if loaded_lists[i].get("list_name", "") == cur_list_name:
			if data_source != null and data_source.has_method(get_listed_method):
				_export_ymhpack(data_source.call(get_listed_method, loaded_lists[i]), downloads_dir, cur_list_name + "_pack")
				return


func _on_export_folder_pressed():
	var found_names = _scan_directory_for_files(dir_path, ext_names)
	
	if found_names.empty():
		$"%Printer".text = "No files found to export in: " + dir_path
		return
	
	var paths = PoolStringArray()
	for fname in found_names:
		paths.append(dir_path.plus_file(fname))
	
	var downloads_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	_export_ymhpack(paths, downloads_dir, dir_name + "_pack")


func _on_android_file_picked(
	temp_path: String,
	mime_type: String,
	_directory: String,
	_extensions: PoolStringArray
) -> void:
	copy_file_to_directory(temp_path, _directory, _extensions)
	Directory.new().remove(temp_path)


func _report_from_directory() -> void:
	var found := _scan_directory_for_files(dir_path, ext_names)
	
	if found.empty():
		$"%Printer".text = "No mod files found"
	else:
		$"%Printer".text = "Mods found: " + PoolStringArray(found).join(", ")


func _scan_directory_for_files(
	_directory: String,
	_extensions: PoolStringArray,
	_all_files = false,
	_full_path = false
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
				if _all_files or "." + file_name.get_extension().to_lower() == extension:
					var final_path = _directory.plus_file(file_name) if _full_path else file_name
					results.append(final_path)
					break
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	return results


func select_file_from_directory(
	_args: Array,
	_extensions: PoolStringArray = [],
	_access_mode = FileDialog.ACCESS_FILESYSTEM,
	_function = "copy_file_to_directory"
):
	var dialog := FileDialog.new()
	
	dialog.theme = preload("res://theme.tres")
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = _access_mode
	
	var fixed_exts := PoolStringArray()
	for extension in _extensions:
		fixed_exts.append("*" + extension)
	if fixed_exts.size() > 0:
		dialog.filters = PoolStringArray([fixed_exts.join(",") + " ; Your Only Move Is Hustle Files"])
	
	dialog.rect_min_size = Vector2(500, 300)
	if _access_mode == FileDialog.ACCESS_FILESYSTEM:
		dialog.current_dir = OS.get_environment("USERPROFILE") + "/Downloads"
	
	add_child(dialog)
	
	dialog.connect("file_selected", self, _function, _args)
	
	dialog.popup_centered()
	dialog.connect("popup_hide", dialog, "queue_free")


func copy_file_to_directory(
	_path: String,
	_directory: String,
	_extensions: PoolStringArray,
	_update_folder = true
) -> bool:
	var ext = "." + _path.get_extension().to_lower()
	
	if _extensions.size() > 0 and not ext in _extensions:
		$"%Printer".text = (
			"Failed to copy file, it doesn't match the extensions: "
			+ _extensions.join(", ")
		)
		return false
	
	if ext == ".ymhpack":
		_import_ymhpack(_path)
		return true
	
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
		option_button.add_item(item.get("list_name", "default"))
	
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
	cur_list_name = data.get("list_name", "default")
	save_list(data, "_current_state")
	save_list(
		{"selected_list_name": cur_list_name},
		"_last_selected"
	)


func save_current_list(name_text: String, default = false) -> String:
	if data_source == null or not data_source.has_method(get_data_method):
		push_warning("no data_source / get method set")
		return ""
	
	var data: Dictionary = data_source.call(get_data_method, default)
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
		list_name = "default"
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
	
	for item in items:
		if item.get("list_name", "") == "default":
			return items
	
	if data_source == null or not data_source.has_method(get_data_method):
		return items
	
	var data: Dictionary = data_source.call(get_data_method, true)
	var clean_name = Utils.filter_filename("default")
	var saved_name = save_list(data, clean_name)
	items.append(data)
	
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
		list_dir_path.plus_file(cur_list_name) + ".ymhlist",
		downloads_dir,
		[LIST_EXT_NAME],
		false
	)


func _on_delete_file_pressed():
	if cur_item_path == "":
		return
	_mark_for_deletion([cur_item_path])


func _on_delete_listed_pressed():
	for i in loaded_lists.size():
		if loaded_lists[i].get("list_name", "") == cur_list_name:
			if data_source != null and data_source.has_method(get_listed_method):
				_mark_for_deletion(data_source.call(get_listed_method, loaded_lists[i]))
				return


func _on_delete_folder_pressed():
	_mark_for_deletion(_scan_directory_for_files(dir_path, ext_names, true, true))


func _mark_for_deletion(paths: PoolStringArray):
	if paths.size() < 1:
		return
	
	var save_path := "user://lists/files_to_delete.ymhlist"
	var data = []
	var file = File.new()
	if file.file_exists(save_path):
		file.open(save_path, File.READ)
		data = file.get_var()
		file.close()
	
	for path in paths:
		data.append(path)
	
	var file2 = File.new()
	file2.open(save_path, File.WRITE)
	file2.store_var(data, true)
	file2.close()
	
	get_tree().quit()
