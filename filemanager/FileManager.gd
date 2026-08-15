extends VBoxContainer

var current_list: Dictionary = {}

export var directory: String = "user://mods"
export var filters: PoolStringArray = ["zip", "yomod"]

# https://github.com/pattlebass/Godot-File-Picker
var android_picker


func _ready():
	$"%Import".connect("pressed", self, "_on_import_pressed")
	$"%SaveList".connect("pressed", self, "_on_save_list_pressed")
	
	if OS.get_name() == "Android" and Engine.has_singleton("GodotFilePicker"):
		android_picker = Engine.get_singleton("GodotFilePicker")
		android_picker.connect("file_picked", self, "_on_android_file_picked", [directory, filters])


func _on_import_pressed():
	if OS.get_name() == "Android":
		if android_picker:
			android_picker.openFilePicker("*/*")
		else:
			_report_from_directory()
	else:
		select_file_from_directory(directory, filters)


func _on_android_file_picked(temp_path: String, mime_type: String, _directory: String, _filters: PoolStringArray) -> void:
	save_file_to_directory(temp_path, _directory, _filters)
	Directory.new().remove(temp_path)


# Android fallback on no plugin installed - VineRaio
func _report_from_directory() -> void:
	var found := _scan_directory_for_files(directory, filters)
	if found.empty():
		$"%Printer".text = "No mod files found"
	else:
		$"%Printer".text = "Mods found: " + PoolStringArray(found).join(", ")


func _scan_directory_for_files(_directory: String, _filters: PoolStringArray) -> Array:
	var results := []
	var dir = Directory.new()
	if dir.open(_directory) != OK:
		return results
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			for filter in _filters:
				if file_name.get_extension().to_lower() == filter:
					results.append(file_name)
					break
		file_name = dir.get_next()
	dir.list_dir_end()
	return results


func select_file_from_directory(_directory: String, _filters: PoolStringArray = []):
	var dialog := FileDialog.new()
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	var patterns := PoolStringArray()
	for filter in _filters:
		patterns.append("*." + filter)
	dialog.filters = PoolStringArray([patterns.join(", ") + " ; Your Only Move Is Hustle Files"])
	
	dialog.rect_min_size = Vector2(400, 200)
	dialog.current_dir = OS.get_environment("USERPROFILE") + "/Downloads"
	add_child(dialog)
	dialog.connect("file_selected", self, "save_file_to_directory", [_directory, _filters])
	dialog.popup_centered()


func save_file_to_directory(_path: String, _directory: String, _filters: PoolStringArray) -> bool:
	var ext = _path.get_extension().to_lower()
	if not ext in _filters:
		$"%Printer".text = "Failed to import file, it doesn't match the filters: " + _filters.join(", ")
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
			return true
		else:
			$"%Printer".text = "Copy reported OK but file not found at destination"
			return false
	else:
		$"%Printer".text = "Failed to import file, error code: " + str(err)
		return false


func _on_save_list_pressed():
	# use current_list here - vineraio
	pass
