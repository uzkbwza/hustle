extends CanvasLayer
class_name FileManagerInterface

# ============================================================================
# FileManagerInterface
# ============================================================================
# Instance one of these per menu that needs "browse/import/export/save a
# named list of files" behavior (mods, skins, whatever). All I/O is
# delegated to the FileManager autoload. All communication with whatever
# owns this instance happens through signals - never has_method()/call().
#
# Signal contract your owner must implement (connect BEFORE calling setup(),
# or any time before the first button press):
#
#   get_data_requested(use_default: bool, result: Dictionary)
#       Fill result["data"] with the Dictionary describing current state.
#       Called synchronously - emit_signal() returns only after your
#       handler runs, so writing into `result` here is safe.
#
#   apply_data_requested(data: Dictionary)
#       Apply the given state. Fire-and-forget, no return value needed.
#
#   get_listed_requested(list_data: Dictionary, result: Dictionary)
#       Fill result["paths"] with a PoolStringArray of file paths that
#       belong to the given saved list (used by Export List / Delete List
#       as a set).
#
#   sort_requested(list_data_array: Array, result: Dictionary)
#       Optional. Fill result["data"] with a sorted copy of the array if
#       you care about list ordering in the dropdown; otherwise just leave
#       result empty and the unsorted array is used.
#
# Example wiring from the owning menu script:
#
#   onready var fm := $FileManagerInterface
#   func _ready():
#       fm.connect("get_data_requested", self, "_on_fm_get_data")
#       fm.connect("apply_data_requested", self, "_on_fm_apply_data")
#       fm.connect("get_listed_requested", self, "_on_fm_get_listed")
#       fm.setup("mods", PoolStringArray([".zip", ".ymhpack"]))
#       close_btn.connect("pressed", fm, "_on_close_pressed")
#       open_btn.connect("pressed", fm, "_on_open_pressed")
#
#   func _on_fm_get_data(use_default, result):
#       result["data"] = {"selected": selected_mod_paths}
#
#   func _on_fm_apply_data(data):
#       selected_mod_paths = data.get("selected", [])
#       _refresh_mod_toggles()
#
#   func _on_fm_get_listed(list_data, result):
#       result["paths"] = PoolStringArray(list_data.get("selected", []))
# ============================================================================

signal get_data_requested(use_default, result)
signal apply_data_requested(data)
signal get_listed_requested(list_data, result)
signal sort_requested(list_data_array, result)
signal folder_updated(path)  # forwarded from FileManager for this instance's category

var dir_name := "mods"
var ext_names: PoolStringArray = [".zip", ".ymhpack"]
var dir_path := "user://mods"
var list_dir_path := "user://lists/mods"

var loaded_lists := []
var cur_item_path := ""
var cur_list_name := ""
var _is_initialized := false
var _pending_inbox := []  # untrusted .ymhpack files awaiting user confirmation

onready var option_button = $"%OptionButton"
onready var list_edit = $"%ListEdit"
onready var printer = $"%Printer"


func _ready() -> void:
	$"%Window".hide()
	if Global.is_mobile_device:
		$"%ExportFileCustom".hide()

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

	FileManager.connect("status_message", self, "_on_status_message")
	FileManager.connect("file_copied", self, "_on_file_copied")
	FileManager.connect("inbox_files_pending", self, "_on_inbox_files_pending")

	# Re-scan now that we are connected — catches packs that arrived
	# before this node's _ready() ran (cold start from file tap).
	if Global.is_mobile_device:
		call_deferred("_recheck_inbox")


func setup(
	_dir_name: String,
	_ext_names: PoolStringArray,
	_use_game_folder := false
) -> void:
	dir_name = _dir_name
	ext_names = _ext_names
	
	if _use_game_folder:
		var install_dir = OS.get_executable_path().get_base_dir()
		if OS.get_name() == "OSX":
			install_dir = install_dir.get_base_dir().get_base_dir().get_base_dir()
		dir_path = install_dir.plus_file(_dir_name)
	else:
		dir_path = "user://".plus_file(_dir_name)
	
	list_dir_path = "user://lists".plus_file(_dir_name)
	
	FileManager.register_category(dir_name, dir_path)
	_restore_current_state()


func _exit_tree() -> void:
	FileManager.unregister_category(dir_name)


func _on_status_message(text: String) -> void:
	printer.text = text


func _on_file_copied(path: String, category: String) -> void:
	if category == dir_name:
		emit_signal("folder_updated", path)


# ---------------------------------------------------------------------------
# Signal-based data request helpers (out-param dictionaries)
# ---------------------------------------------------------------------------

func _request_data(use_default: bool) -> Dictionary:
	var result := {}
	emit_signal("get_data_requested", use_default, result)
	return result.get("data", {})


func _request_apply(data: Dictionary) -> void:
	emit_signal("apply_data_requested", data)


func _request_listed_paths(list_data: Dictionary) -> PoolStringArray:
	var result := {}
	emit_signal("get_listed_requested", list_data, result)
	return result.get("paths", PoolStringArray())


func _maybe_sort(data: Array) -> Array:
	var result := {}
	emit_signal("sort_requested", data, result)
	return result.get("data", data)


# Reorders a list-of-lists array so the list named "default" always sits at
# the top of the dropdown, keeping the relative order of everything else.
func _sort_default_first(data: Array) -> Array:
	var result := []
	for item in data:
		if typeof(item) == TYPE_DICTIONARY and item.get("list_name", "") == "default":
			result.insert(0, item)
		else:
			result.append(item)
	return result


# ---------------------------------------------------------------------------
# Window open/close
# ---------------------------------------------------------------------------

func _on_open_pressed() -> void:
	if not _is_initialized:
		_refresh_lists_menu()
		_is_initialized = true
	
	if OS.get_name() == "Android" and FileManager.android_picker:
		if not FileManager.android_picker.is_connected("file_picked", self, "_on_android_file_picked"):
			FileManager.android_picker.connect("file_picked", self, "_on_android_file_picked")
	
	$"%Window".show()
	_show_inbox_confirm_if_pending()


func _on_close_pressed() -> void:
	if OS.get_name() == "Android" and FileManager.android_picker:
		if FileManager.android_picker.is_connected("file_picked", self, "_on_android_file_picked"):
			FileManager.android_picker.disconnect("file_picked", self, "_on_android_file_picked")

	$"%Window".hide()


func _on_inbox_files_pending(files: Array) -> void:
	# Stage the received packages; they are NOT imported until the user
	# explicitly confirms in the dialog.
	_pending_inbox = files
	_show_inbox_confirm_if_pending()


func _recheck_inbox() -> void:
	# Called via call_deferred from _ready() so the inbox signal (which may
	# have fired before we connected) is re-emitted with the current files.
	FileManager._check_ymhpack_inbox()


func _show_inbox_confirm_if_pending() -> void:
	if _pending_inbox.empty():
		return
	var dialog := AcceptDialog.new()
	dialog.theme = preload("res://theme.tres")
	dialog.title = "Found received packages"
	dialog.dialog_text = "%d package file(s) were received. Import them now?" % _pending_inbox.size()
	dialog.get_ok().text = "Import"
	add_child(dialog)
	dialog.connect("confirmed", self, "_on_inbox_import_confirmed", [dialog])
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()


func _on_inbox_import_confirmed(dialog: AcceptDialog) -> void:
	_pending_inbox = []
	FileManager.import_inbox()


# ---------------------------------------------------------------------------
# Import
# ---------------------------------------------------------------------------

func _on_import_files_pressed() -> void:
	if OS.get_name() == "Android":
		if FileManager.android_picker:
			FileManager.android_picker.openFilePicker("*/*")
		else:
			_report_from_directory()
	else:
		_select_file_from_directory()


func _on_android_file_picked(temp_path: String, _mime_type: String) -> void:
	FileManager.copy_file_to_directory(temp_path, dir_path, ext_names, dir_name)
	Directory.new().remove(temp_path)


func _report_from_directory() -> void:
	var found := FileManager.scan_directory_for_files(dir_path, ext_names)
	printer.text = "No mod files found" if found.empty() else "Mods found: " + found.join(", ")


func _select_file_from_directory() -> void:
	var dialog := FileDialog.new()
	dialog.theme = preload("res://theme.tres")
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_dir = OS.get_environment("USERPROFILE") + "/Downloads"
	dialog.rect_min_size = Vector2(500, 300)
	
	var filters = PoolStringArray()
	for extension in ext_names:
		filters.push_back("*" + extension + " ; Game Files")
	dialog.filters = filters
	
	add_child(dialog)
	dialog.connect("file_selected", self, "_on_file_picked_for_import")
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()


func _on_file_picked_for_import(path: String) -> void:
	FileManager.copy_file_to_directory(path, dir_path, ext_names, dir_name)


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

func _on_export_file_pressed() -> void:
	if cur_item_path == "":
		return
	var downloads = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	FileManager.export_pack(
		[{"path": cur_item_path, "category": dir_name}],
		downloads,
		cur_item_path.get_file().get_basename()
	)


func _on_export_file_custom_pressed() -> void:
	var downloads = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	var dialog := FileDialog.new()
	dialog.theme = preload("res://theme.tres")
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_USERDATA
	dialog.current_dir = downloads
	dialog.rect_min_size = Vector2(500, 300)
	
	add_child(dialog)
	dialog.connect("file_selected", self, "_on_custom_file_picked_for_export", [downloads])
	dialog.connect("popup_hide", dialog, "queue_free")
	dialog.popup_centered()


func _on_custom_file_picked_for_export(path: String, destination_dir: String) -> void:
	FileManager.export_pack([{"path": path, "category": dir_name}], destination_dir, path.get_file().get_basename())


func _on_export_listed_pressed() -> void:
	for list in loaded_lists:
		if list.get("list_name", "") == cur_list_name:
			var paths = _request_listed_paths(list)
			var entries := []
			for p in paths:
				entries.append({"path": p, "category": dir_name})
			var downloads = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
			FileManager.export_pack(entries, downloads, cur_list_name + "_pack")
			return


func _on_export_folder_pressed() -> void:
	var found_names = FileManager.scan_directory_for_files(dir_path, ext_names)
	if found_names.empty():
		printer.text = "No files found to export in: " + dir_path
		return
	
	var entries := []
	for fname in found_names:
		entries.append({"path": dir_path.plus_file(fname), "category": dir_name})
	
	var downloads = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	FileManager.export_pack(entries, downloads, dir_name + "_pack")


func _on_export_list_pressed() -> void:
	if cur_list_name == "":
		return
	var downloads = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	var src_path = list_dir_path.plus_file(cur_list_name) + FileManager.LIST_EXT
	FileManager.copy_file_to_directory(src_path, downloads, PoolStringArray([FileManager.LIST_EXT]), dir_name)


# ---------------------------------------------------------------------------
# Lists (save / load / apply)
# ---------------------------------------------------------------------------

func _on_save_list_pressed() -> void:
	save_current_list(list_edit.text)


func save_current_list(name_text: String, use_default := false) -> String:
	var data = _request_data(use_default)
	var clean_name = Utils.filter_filename(name_text)
	var saved_name = FileManager.save_list(list_dir_path, data, clean_name)
	_refresh_lists_menu()
	select_list_by_name(saved_name)
	return saved_name


func _refresh_lists_menu() -> void:
	var raw = FileManager.load_all_lists(list_dir_path)
	raw = _maybe_sort(raw)
	raw = _sort_default_first(raw)
	
	loaded_lists = []
	option_button.clear()

	for item in raw:
		if item.get("list_name", "") == "_current_state":
			continue
		loaded_lists.append(item)
		option_button.add_item(item.get("list_name", "default"))
	
	_highlight_selected_in_dropdown()


func _restore_current_state() -> void:
	var state = FileManager.load_list(list_dir_path, "_current_state")
	cur_list_name = state.get("selected_list_name", "")
	var data = state.get("data", {})
	# If the latest selected list was deleted, don't reapply its stale data.
	# Fall through to the caller's defaults (all styles ON) instead.
	if cur_list_name != "" and not File.new().file_exists(list_dir_path.plus_file(cur_list_name) + FileManager.LIST_EXT):
		FileManager.delete_list(list_dir_path, "_current_state")
		cur_list_name = ""
		return
	if not data.empty():
		_request_apply(data)


func _highlight_selected_in_dropdown() -> void:
	for i in loaded_lists.size():
		if loaded_lists[i].get("list_name", "") == cur_list_name:
			option_button.selected = i
			return
	option_button.selected = -1


func _on_option_button_item_selected(index: int) -> void:
	if loaded_lists.size() > index:
		_apply_list(loaded_lists[index])


func _apply_list(data: Dictionary) -> void:
	_request_apply(data)
	cur_list_name = data.get("list_name", "default")
	FileManager.save_list(list_dir_path, {
		"selected_list_name": cur_list_name,
		"data": data,
	}, "_current_state")


func select_list_by_name(list_name: String) -> void:
	for i in loaded_lists.size():
		if loaded_lists[i].get("list_name", "") == list_name:
			option_button.selected = i
			_on_option_button_item_selected(i)
			return


func _on_list_edit_text_entered(new_text: String) -> void:
	if new_text != "_current_state":
		save_current_list(new_text)
	list_edit.clear()


# ---------------------------------------------------------------------------
# Delete
# ---------------------------------------------------------------------------

func _on_delete_list_pressed() -> void:
	if cur_list_name == "":
		return
	FileManager.delete_list(list_dir_path, cur_list_name)
	# The freshly-deleted list can no longer be "the current selection".
	# Clear _current_state so a restart doesn't reapply its stale data.
	FileManager.delete_list(list_dir_path, "_current_state")
	cur_list_name = ""
	_refresh_lists_menu()


func _on_delete_file_pressed() -> void:
	if cur_item_path == "":
		return
	FileManager.mark_for_deletion(PoolStringArray([cur_item_path]))


func _on_delete_listed_pressed() -> void:
	for list in loaded_lists:
		if list.get("list_name", "") == cur_list_name:
			FileManager.mark_for_deletion(_request_listed_paths(list))
			return


func _on_delete_folder_pressed() -> void:
	FileManager.mark_for_deletion(FileManager.scan_directory_for_files(dir_path, ext_names, true, true))
