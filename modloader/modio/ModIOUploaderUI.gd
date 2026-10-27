extends Window

signal upload_complete

export(String, "mod", "guide", "collection") var kind := "mod"

onready var _upload_form: VBoxContainer = $"%UploadForm"
onready var _name_edit: LineEdit = $"%NameEdit"
onready var _summary_edit: LineEdit = $"%SummaryEdit"
onready var _description_edit: TextEdit = $"%DescriptionEdit"
onready var _tags_edit: LineEdit = $"%TagsEdit" if kind != "collection" else null
onready var _logo_edit: LineEdit = $"%LogoEdit"
onready var _logo_browse_btn: Button = $"%LogoBrowse"
onready var _cancel_btn: Button = $"%CancelBtn"
onready var _status_label: Label = $"%StatusLabel"
onready var _account_bar = $"%AccountBar"
onready var _logo_dialog: FileDialog = $"%LogoDialog"

onready var _create_btn: Button = $"%CreateModBtn" if kind == "mod" else $"%CreateBtn"
onready var _zip_edit: LineEdit = $"%ZipEdit" if kind == "mod" else null
onready var _zip_browse_btn: Button = $"%ZipBrowse" if kind == "mod" else null
onready var _version_edit: LineEdit = $"%VersionEdit" if kind == "mod" else null
onready var _changelog_edit: LineEdit = $"%ChangelogEdit" if kind == "mod" else null
onready var _progress_row = $"%ProgressRow" if kind == "mod" else null
onready var _progress_bar: ProgressBar = $"%ProgressBar" if kind == "mod" else null
onready var _progress_text: Label = $"%ProgressText" if kind == "mod" else null
onready var _upload_file_btn: Button = $"%UploadFileBtn" if kind == "mod" else null
onready var _zip_dialog: FileDialog = $"%ZipDialog" if kind == "mod" else null
onready var _mod_ids_edit: LineEdit = $"%ModIdsEdit" if kind == "collection" else null
onready var _visible_check: CheckButton = $"%VisibleCheck" if kind == "collection" else null

var _api: Object = null
var _created_mod_id := 0
var _uploading := false
var _pulse := 0.0
var _picker_target := ""
var _temp_files := []

const WINDOW_SIZE := Vector2(560, 340)
const MOBILE_SCREEN_MARGIN := 8.0
const UPLOAD_TEMP_DIR := "user://modio_uploads"


func _ready() -> void:
	_apply_kind()
	$"%Close".connect("pressed", self, "close_menu")
	_logo_browse_btn.connect("pressed", self, "_browse_logo")
	_create_btn.connect("pressed", self, "_on_create")
	_cancel_btn.connect("pressed", self, "_on_cancel")
	_logo_dialog.connect("file_selected", self, "_on_logo_selected")
	_account_bar.connect("signed_in", self, "_on_auth_changed")
	_account_bar.connect("signed_out", self, "_on_auth_changed")

	var controls = [
		$"%Close",
		_name_edit, _summary_edit, _description_edit,
		_logo_edit, _logo_browse_btn, _create_btn, _cancel_btn,
	]
	if _tags_edit != null:
		controls.append(_tags_edit)
	if _zip_edit != null:
		_zip_browse_btn.connect("pressed", self, "_browse_zip")
		_upload_file_btn.connect("pressed", self, "_on_upload_file")
		_zip_dialog.connect("file_selected", self, "_on_zip_selected")
		controls.append_array([_zip_edit, _zip_browse_btn, _upload_file_btn, _version_edit, _changelog_edit])
	if _mod_ids_edit != null:
		controls.append(_mod_ids_edit)
	if _visible_check != null:
		controls.append(_visible_check)
	UIManager.register_menu(self, controls)

	Global.connect("mobile_ui_changed", self, "adjust_ui")
	adjust_ui(Global.mobile_ui)

	_api = ModIOUploadAPI.new()
	add_child(_api)
	_api.connect(kind + "_created", self, "_on_created")
	_api.connect(kind + "_create_failed", self, "_on_create_failed")
	if kind == "mod":
		_api.connect("file_upload_started", self, "_on_upload_started")
		_api.connect("file_upload_done", self, "_on_upload_done")
		_api.connect("file_upload_failed", self, "_on_upload_failed")


func _apply_kind() -> void:
	var is_mod := kind == "mod"
	var is_collection := kind == "collection"
	$"%Title".text = "Upload %s to mod.io" % kind.capitalize()
	$"%NameLabel".text = "%s Name:" % kind.capitalize()
	_name_edit.placeholder_text = "My %s" % kind.capitalize()
	$"%TagsRow".visible = not is_collection
	$"%ZipRow".visible = is_mod
	$"%VersionRow".visible = is_mod
	$"%ChangelogRow".visible = is_mod
	$"%ProgressRow".visible = is_mod
	$"%CreateModBtn".visible = is_mod
	$"%UploadFileBtn".visible = is_mod
	$"%CreateBtn".visible = not is_mod
	$"%ModIdsRow".visible = is_collection
	$"%VisibleCheck".visible = is_collection
	$"%CreateBtn".text = "Upload %s" % kind.capitalize()


func open() -> void:
	_logo_dialog.hide()
	if _zip_dialog != null:
		_zip_dialog.hide()
	adjust_ui(Global.mobile_ui)
	show()
	raise()
	_reset_form()
	_check_auth_state()


func adjust_ui(is_mobile: bool) -> void:
	var target = WINDOW_SIZE
	if is_mobile:
		var screen = get_viewport_rect().size
		target.x = min(WINDOW_SIZE.x, max(1.0, screen.x - MOBILE_SCREEN_MARGIN * 2.0))
		target.y = min(WINDOW_SIZE.y, max(1.0, screen.y - MOBILE_SCREEN_MARGIN * 2.0))
	margin_left = -target.x * 0.5
	margin_right = target.x * 0.5
	margin_top = -target.y * 0.5
	margin_bottom = target.y * 0.5


func _process(delta) -> void:
	if kind != "mod" or not _uploading:
		return
	_pulse = fmod(_pulse + delta * 80.0, 100.0)
	_progress_bar.value = _pulse


func _check_auth_state() -> void:
	_account_bar.refresh()
	var signed_in = ModIOAuth.is_logged_in()
	_upload_form.visible = signed_in
	_create_btn.disabled = not signed_in or _uploading or (kind == "mod" and _created_mod_id != 0)
	if _upload_file_btn != null:
		_upload_file_btn.disabled = not signed_in or _created_mod_id == 0
	if not signed_in:
		_update_status("Sign in to mod.io to upload a %s." % kind)
	elif kind == "mod" and _created_mod_id != 0:
		_update_status("Ready to upload a file for mod ID %d." % _created_mod_id)
	elif not _uploading:
		_update_status("Fill in the form and click " + _create_btn.text)


func _on_auth_changed() -> void:
	_check_auth_state()


func _reset_form() -> void:
	_clear_temp_files()
	_name_edit.text = ""
	_summary_edit.text = ""
	_description_edit.text = ""
	if _tags_edit != null:
		_tags_edit.text = ""
	_logo_edit.text = ""
	if _zip_edit != null:
		_zip_edit.text = ""
	if _mod_ids_edit != null:
		_mod_ids_edit.text = ""
	if _visible_check != null:
		_visible_check.set_pressed_no_signal(false)
	if _version_edit != null:
		_version_edit.text = "1.0"
		_changelog_edit.text = "Initial release"
		_progress_row.visible = false
		_progress_bar.value = 0
		_progress_text.text = "0 / 0 MB"
	_create_btn.disabled = false
	if _upload_file_btn != null:
		_upload_file_btn.disabled = true
	_created_mod_id = 0
	_uploading = false


func _update_status(message: String) -> void:
	_status_label.text = message


func close_menu() -> void:
	_disconnect_android_picker()
	_logo_dialog.hide()
	if _zip_dialog != null:
		_zip_dialog.hide()
	_clear_temp_files()
	hide()


func _on_cancel() -> void:
	_api.cancel_upload()
	_uploading = false
	_reset_form()
	_check_auth_state()
	close_menu()


func _browse_logo() -> void:
	if _open_android_picker("logo"):
		return
	_logo_dialog.popup_centered_ratio(0.8)


func _browse_zip() -> void:
	if _open_android_picker("zip"):
		return
	_zip_dialog.popup_centered_ratio(0.8)


func _open_android_picker(target: String) -> bool:
	if OS.get_name() != "Android" or not FileManager.android_picker:
		return false
	_picker_target = target
	if not FileManager.android_picker.is_connected("file_picked", self, "_on_android_file_picked"):
		FileManager.android_picker.connect("file_picked", self, "_on_android_file_picked")
	FileManager.android_picker.openFilePicker("*/*")
	return true


func _disconnect_android_picker() -> void:
	if FileManager.android_picker and FileManager.android_picker.is_connected("file_picked", self, "_on_android_file_picked"):
		FileManager.android_picker.disconnect("file_picked", self, "_on_android_file_picked")
	_picker_target = ""


func _on_android_file_picked(temp_path: String, _mime_type: String) -> void:
	var target = _picker_target
	_picker_target = ""
	if target == "":
		return
	if not File.new().file_exists(temp_path):
		_update_status("Couldn't read the selected file.")
		return
	var file_name = FileManager._safe_name(temp_path.get_file(), "upload.bin")
	var dest_dir = UPLOAD_TEMP_DIR.plus_file(target)
	var dir = Directory.new()
	if dir.make_dir_recursive(dest_dir) != OK and not dir.dir_exists(dest_dir):
		_update_status("Couldn't prepare the upload folder.")
		return
	var dest_path = dest_dir.plus_file(file_name)
	if dir.copy(temp_path, dest_path) != OK:
		_update_status("Couldn't copy the selected file.")
		return
	if temp_path != dest_path:
		dir.remove(temp_path)
	if target == "zip" and not _is_zip(dest_path):
		dir.remove(dest_path)
		_update_status("Only .zip files can be uploaded")
		return
	_temp_files.append(dest_path)
	if target == "zip":
		_zip_edit.text = dest_path
		_update_status("Selected %s" % dest_path.get_file())
	else:
		_logo_edit.text = dest_path
		_update_status("Selected %s" % dest_path.get_file())


func _clear_temp_files() -> void:
	var dir = Directory.new()
	for path in _temp_files:
		if dir.file_exists(path):
			dir.remove(path)
	_temp_files.clear()


func _on_logo_selected(path: String) -> void:
	_logo_edit.text = path


func _on_zip_selected(path: String) -> void:
	if not _is_zip(path):
		_zip_edit.text = ""
		_update_status("Only .zip files can be uploaded")
		return
	_zip_edit.text = path


func _is_zip(path: String) -> bool:
	return path.get_extension().to_lower() == "zip"


func _tags() -> Array:
	var tags = []
	if _tags_edit == null:
		return tags
	for part in _tags_edit.text.split(","):
		var tag = part.strip_edges()
		if tag != "" and not tag in tags:
			tags.append(tag)
	return tags


func _on_create(_text = "") -> void:
	if _uploading:
		return
	var item_name = _name_edit.text.strip_edges()
	var summary = _summary_edit.text.strip_edges()
	var description = _description_edit.text.strip_edges()
	var logo_path = _logo_edit.text.strip_edges()

	if kind == "mod":
		if item_name == "":
			_update_status("Mod name is required")
			return
		if summary == "":
			_update_status("Summary is required")
			return
		if logo_path == "" or not File.new().file_exists(logo_path):
			_update_status("Select a logo image")
			return
		_create_btn.disabled = true
		_update_status("Creating mod on mod.io...")
		_api.create_mod(item_name, summary, description, logo_path, _tags())
		return

	if item_name == "":
		_update_status("%s name is required" % kind.capitalize())
		return
	if logo_path == "" or not File.new().file_exists(logo_path):
		_update_status("Select a logo image")
		return

	if kind == "guide":
		if item_name.length() > 70:
			_update_status("Guide names can be at most 70 characters")
			return
		if summary.length() < 20 or summary.length() > 250:
			_update_status("The summary must be between 20 and 250 characters")
			return
		if description == "":
			_update_status("A description is required")
			return
		var tags = _tags()
		if tags.empty():
			_update_status("Add at least one tag")
			return
		if tags.size() > 7:
			_update_status("Guides can have at most 7 tags")
			return
		_uploading = true
		_create_btn.disabled = true
		_update_status("Uploading guide...")
		_api.create_guide(item_name, summary, description, logo_path, tags)
		return

	if item_name.length() > 50:
		_update_status("Collection names can be at most 50 characters")
		return
	if summary.length() > 250:
		_update_status("The summary can be at most 250 characters")
		return
	if description.length() > 50000:
		_update_status("The description is too long")
		return
	var mod_ids = []
	var text = _mod_ids_edit.text.replace("\n", ",").replace(" ", ",")
	for part in text.split(","):
		var value = part.strip_edges()
		if value == "":
			continue
		if not value.is_valid_integer():
			_update_status("Mod IDs must be whole numbers")
			return
		mod_ids.append(int(value))
	_uploading = true
	_create_btn.disabled = true
	_update_status("Uploading collection...")
	_api.create_collection(item_name, summary, description, logo_path, mod_ids, _visible_check.pressed)


func _on_upload_file() -> void:
	if _created_mod_id == 0:
		_update_status("Create mod first")
		return
	var zip_path = _zip_edit.text.strip_edges()
	if zip_path == "" or not File.new().file_exists(zip_path):
		_update_status("Select a valid mod zip file")
		return
	if not _is_zip(zip_path):
		_update_status("Only .zip files can be uploaded")
		return
	var version = _version_edit.text.strip_edges()
	_progress_row.visible = true
	_progress_bar.value = 0
	_progress_text.text = "Uploading..."
	_upload_file_btn.disabled = true
	_create_btn.disabled = true
	_update_status("Uploading file...")
	_api.upload_file(_created_mod_id, zip_path, "1.0" if version == "" else version,
		_changelog_edit.text.strip_edges(), true)


func _on_created(id: int, _data: Dictionary) -> void:
	_uploading = false
	_create_btn.disabled = true
	if kind == "mod":
		_created_mod_id = id
		_upload_file_btn.disabled = false
		_update_status("Mod created (ID: %d). Now upload the mod file." % id)
		return
	_update_status("%s uploaded (ID: %d)." % [kind.capitalize(), id])
	emit_signal("upload_complete")


func _on_create_failed(error: String) -> void:
	_uploading = false
	_create_btn.disabled = false
	_update_status("Failed to create: " + error)


func _on_upload_started(total_bytes: int) -> void:
	_uploading = true
	_progress_bar.value = 0
	_progress_text.text = "%.1f MB" % (total_bytes / 1048576.0)


func _on_upload_done(modfile_id: int, _data: Dictionary) -> void:
	_uploading = false
	_progress_row.visible = false
	_upload_file_btn.disabled = false
	_create_btn.disabled = true
	_update_status("Upload complete! Modfile ID: %d" % modfile_id)
	emit_signal("upload_complete")


func _on_upload_failed(error: String) -> void:
	_uploading = false
	_progress_row.visible = false
	_upload_file_btn.disabled = _created_mod_id == 0
	_create_btn.disabled = _created_mod_id != 0
	_update_status("Upload failed: " + error)
