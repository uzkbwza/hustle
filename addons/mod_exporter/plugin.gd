tool
extends EditorPlugin

const ModZipper = preload("res://addons/mod_exporter/mod_zipper.gd")
const MENU_ITEM = "Export Mod Zip..."

var dialog
var folder_select
var path_edit
var status
var save_dialog


func _enter_tree():
	add_tool_menu_item(MENU_ITEM, self, "_open")


func _exit_tree():
	remove_tool_menu_item(MENU_ITEM)
	if dialog:
		dialog.queue_free()
	if save_dialog:
		save_dialog.queue_free()


func _open(_ud = null):
	if dialog == null:
		_build()
	folder_select.clear()
	for f in ModZipper.find_mod_folders():
		folder_select.add_item(f.trim_prefix("res://"))
	status.text = "" if folder_select.get_item_count() > 0 else "No folder with a _metadata file"
	_suggest_path()
	dialog.popup_centered(Vector2(560, 0) * get_editor_interface().get_editor_scale())


func _build():
	var base = get_editor_interface().get_base_control()
	dialog = AcceptDialog.new()
	dialog.window_title = "Export Mod Zip"
	dialog.get_ok().text = "Export"
	dialog.connect("confirmed", self, "_export")
	var box = VBoxContainer.new()
	dialog.add_child(box)

	folder_select = OptionButton.new()
	folder_select.connect("item_selected", self, "_on_folder_selected")
	box.add_child(folder_select)

	var row = HBoxContainer.new()
	box.add_child(row)
	path_edit = LineEdit.new()
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(path_edit)
	var browse = Button.new()
	browse.text = "..."
	browse.connect("pressed", self, "_browse")
	row.add_child(browse)

	status = Label.new()
	status.autowrap = true
	box.add_child(status)
	base.add_child(dialog)

	save_dialog = EditorFileDialog.new()
	save_dialog.mode = EditorFileDialog.MODE_SAVE_FILE
	save_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	save_dialog.add_filter("*.zip")
	save_dialog.connect("file_selected", self, "_on_path_chosen")
	base.add_child(save_dialog)


func _selected_folder():
	if folder_select.get_item_count() == 0:
		return ""
	return "res://" + folder_select.get_item_text(folder_select.selected)


func _on_folder_selected(_i):
	_suggest_path()


func _suggest_path():
	var folder = _selected_folder()
	if folder == "":
		return
	var dir = path_edit.text.get_base_dir() if path_edit.text != "" else ProjectSettings.globalize_path("res://").get_base_dir()
	path_edit.text = dir.plus_file(folder.trim_prefix("res://") + ".zip")


func _browse():
	save_dialog.current_path = path_edit.text
	save_dialog.popup_centered_ratio(0.6)


func _on_path_chosen(path):
	path_edit.text = path


func _export():
	var folder = _selected_folder()
	if folder == "" or path_edit.text == "":
		return
	var report = ModZipper.export_mod(folder, path_edit.text)
	if report.error != OK:
		status.text = "Export failed (error %d)" % report.error
	else:
		status.text = "Exported %d files + %d imported files, %.1f MB" % [report.files, report.imported_files, report.bytes / 1048576.0]
		if report.missing.size() > 0:
			status.text += "\nNot imported yet: " + PoolStringArray(report.missing).join(", ")
	# AcceptDialog hides on confirm; show the result
	dialog.call_deferred("popup_centered")
