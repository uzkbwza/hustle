extends GridContainer
class_name ModIOBrowserRow

signal collections_pressed(mod_id)
signal description_clicked(mod_id, text, pos)
signal description_hovered(mod_id, text, pos)
signal description_left(mod_id)
signal open_pressed(mod_id)
signal page_pressed(mod_id)
signal subscribe_pressed(mod_id)
signal thumbnail_requested(mod_id, url)

const CARD_COLUMNS := 1
const COMPACT_COLUMNS := 3
const DRAG_CANCEL_DISTANCE := 4.0
const MODIO_IMAGE := preload("res://modloader/modio/ModIOImage.gd")

var mod_id := ""
var mod_data := {}
var description := ""
var summary_text := ""
var subscribed := false
var signed_in := false
var busy := false
var installed := {}
var compact := false
var workshop := false
var square_thumb := false
var _pressed := false
var _press_pos := Vector2.ZERO

onready var thumb: TextureRect = $"%Thumb"
onready var info: VBoxContainer = $"%Info"
onready var name_label: Label = $"%Name"
onready var meta_label: Label = $"%Meta"
onready var summary_label: Label = $"%Summary"
onready var buttons: VBoxContainer = $"%Buttons"
onready var icon_row: HBoxContainer = $"%IconRow"
onready var status_label: Label = $"%Status"
onready var subscribe_icon: TextureButton = $"%Subscribe"
onready var page_icon: TextureButton = $"%Page"
onready var collections_icon: TextureButton = $"%Collections"


func _ready() -> void:
	subscribe_icon.connect("pressed", self, "_on_subscribe_pressed")
	collections_icon.connect("pressed", self, "_on_collections_pressed")
	page_icon.connect("pressed", self, "_on_page_pressed")
	thumb.connect("mouse_entered", self, "_on_thumb_mouse_entered")
	thumb.connect("mouse_exited", self, "_on_thumb_mouse_exited")
	connect("gui_input", self, "_on_card_gui_input")


func setup(mod: Dictionary, is_subscribed: bool = false) -> void:
	mod_data = mod
	mod_id = str(mod.get("id", ""))
	name_label.text = str(mod.get("name", "Unknown"))
	description = _description_text(mod)
	var summary = str(mod.get("summary", "")).strip_edges()
	summary_text = summary
	summary_label.text = summary
	_update_summary_visibility()
	subscribed = is_subscribed
	_refresh_meta()

	var logo = mod.get("logo", {})
	if typeof(logo) != TYPE_DICTIONARY:
		logo = {}
	var url = str(logo.get("thumb_320x180", ""))
	if url == "":
		url = str(logo.get("original", ""))
	if url != "":
		emit_signal("thumbnail_requested", mod_id, url)


func set_compact(value: bool) -> void:
	compact = value
	columns = COMPACT_COLUMNS if value else CARD_COLUMNS
	info.size_flags_horizontal = 3
	buttons.size_flags_horizontal = 0 if value else 3
	icon_row.size_flags_horizontal = 0 if value else 3
	icon_row.alignment = 2 if value else 1
	name_label.max_lines_visible = 1 if value else 2
	summary_label.max_lines_visible = 1 if value else 2
	_apply_thumb_size()
	_update_summary_visibility()


func set_square_thumb(value: bool) -> void:
	square_thumb = value
	_apply_thumb_size()


func _apply_thumb_size() -> void:
	if square_thumb:
		var side = 64 if compact else 128
		thumb.rect_min_size = Vector2(side, side)
		thumb.size_flags_horizontal = 0 if compact else 3
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if compact:
			size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rect_min_size = Vector2(0, 0)
		else:
			size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			rect_min_size = Vector2(side, 0)
		return
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect_min_size = Vector2(0, 0)
	thumb.rect_min_size = Vector2(64, 43) if compact else Vector2(128, 86)
	thumb.size_flags_horizontal = 0 if compact else 3
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if compact else TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _update_summary_visibility() -> void:
	summary_label.visible = compact and summary_text != ""


func set_subscribed(is_subscribed: bool) -> void:
	subscribed = is_subscribed
	_refresh_meta()


func set_signed_in(value: bool) -> void:
	signed_in = value
	_refresh_meta()


func set_workshop(value: bool) -> void:
	workshop = value
	_refresh_meta()


func set_install_state(state: Dictionary) -> void:
	installed = state
	_refresh_meta()


func set_busy(value: bool) -> void:
	busy = value
	subscribe_icon.disabled = value
	_refresh_meta()


func set_status(text: String) -> void:
	status_label.text = text
	status_label.visible = text != ""


func set_thumbnail(texture) -> void:
	if texture != null:
		thumb.texture = texture


func profile_url() -> String:
	return str(mod_data.get("profile_url", ""))


func latest_file_id() -> int:
	var modfile = mod_data.get("modfile", {})
	if typeof(modfile) != TYPE_DICTIONARY:
		return 0
	return int(modfile.get("id", 0))


func tooltip_text() -> String:
	var lines := PoolStringArray()
	var title = str(mod_data.get("name", name_label.text)).strip_edges()
	if title != "":
		lines.append(title)
	var meta = meta_label.text.strip_edges()
	if meta != "":
		lines.append(meta)
	var extra = _tooltip_extra(mod_data)
	if extra != "":
		lines.append(extra)
	if description != "":
		if summary_label.visible and summary_label.text != "":
			lines.append(summary_label.text.strip_edges())
		if description != summary_label.text.strip_edges():
			if lines.size() > 0:
				lines.append("")
			lines.append(description)
	return lines.join("\n").strip_edges()


func _refresh_meta() -> void:
	subscribe_icon.texture_normal = MODIO_IMAGE.icon("unsubscribe") if subscribed else MODIO_IMAGE.icon("subscribe")
	if workshop:
		_refresh_workshop_meta()
		return
	meta_label.text = _mod_meta(mod_data)
	if not installed.empty():
		if bool(installed.get("pending", false)):
			meta_label.text += "  |  queued for next launch"
		else:
			meta_label.text += "  |  installed"
			var latest = latest_file_id()
			if latest > 0 and latest != int(installed.get("file_id", 0)):
				meta_label.text += " (update available)"
	if subscribed:
		subscribe_icon.modulate = Color(1, 0.45, 0.45)
	else:
		subscribe_icon.modulate = Color(0.85, 0.85, 0.85)
	if not signed_in:
		subscribe_icon.hint_tooltip = "Sign in to mod.io to subscribe"
	elif subscribed:
		subscribe_icon.hint_tooltip = "Unsubscribe and delete the mod on next launch"
	else:
		subscribe_icon.hint_tooltip = "Subscribe and download the mod (installs on next launch)"


func _refresh_workshop_meta() -> void:
	meta_label.text = _workshop_meta(mod_data)
	var state = str(installed.get("workshop_state", ""))
	if state == "pending":
		meta_label.text += "  |  queued for next launch"
	elif state == "installed":
		meta_label.text += "  |  installed"
		if int(mod_data.get("workshop_time_updated", 0)) > int(installed.get("time_updated", 0)):
			meta_label.text += " (update available)"
	if subscribed:
		subscribe_icon.modulate = Color(1, 0.45, 0.45)
		subscribe_icon.hint_tooltip = "Unsubscribe and remove this workshop item on next launch"
	else:
		subscribe_icon.modulate = Color(0.85, 0.85, 0.85)
		subscribe_icon.hint_tooltip = "Subscribe and install this workshop item (installs on next launch)"
	collections_icon.hint_tooltip = "Add or remove this item from your collections"
	page_icon.hint_tooltip = "Open this item on Steam"


func _workshop_meta(item: Dictionary) -> String:
	var author = str(item.get("workshop_author", "Steam user"))
	var text = "by " + author
	var size = int(item.get("modfile", {}).get("filesize", 0))
	if size > 0:
		text += "  |  " + _fmt_size(size)
	var up = int(item.get("workshop_votes_up", 0))
	var down = int(item.get("workshop_votes_down", 0))
	if up + down > 0:
		text += "  |  %d%% positive" % int(round(float(up) / float(up + down) * 100.0))
	var tags = item.get("tags", [])
	if typeof(tags) == TYPE_ARRAY and tags.size() > 0:
		var shown := PoolStringArray()
		for tag in tags.slice(0, 2):
			var tag_name = str(tag).strip_edges()
			if tag_name != "":
				shown.append(tag_name)
		if shown.size() > 0:
			text += "  |  " + shown.join(", ")
	return text


func _description_text(mod: Dictionary) -> String:
	var summary = str(mod.get("summary", "")).strip_edges()
	var text = str(mod.get("description_plaintext", "")).strip_edges()
	if text == "":
		text = _strip_html(str(mod.get("description", "")))
	if summary != "" and text.begins_with(summary):
		text = text.substr(summary.length()).strip_edges()
	if text == "":
		text = summary
	return text


func _strip_html(text: String) -> String:
	var regex = RegEx.new()
	if regex.compile("<[^>]*>") != OK:
		return text.strip_edges()
	return regex.sub(text, "", true).strip_edges()


func _mod_meta(mod: Dictionary) -> String:
	var submitted_by = mod.get("submitted_by", {})
	var author = "unknown"
	if typeof(submitted_by) == TYPE_DICTIONARY:
		author = str(submitted_by.get("display_name", submitted_by.get("username", "unknown")))
	var stats = mod.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		stats = {}
	var text = "by %s  |  %s downloads" % [author, _fmt_count(int(stats.get("downloads_total", 0)))]
	if int(stats.get("ratings_total", 0)) > 0:
		var positive = float(stats.get("ratings_positive", 0))
		var total = float(stats.get("ratings_total", 0))
		text += "  |  %d%% positive" % int(round((positive / total) * 100.0))
	var tags = mod.get("tags", [])
	if typeof(tags) == TYPE_ARRAY and tags.size() > 0:
		var shown := PoolStringArray()
		for tag in tags.slice(0, 2):
			var tag_name = ""
			if typeof(tag) == TYPE_DICTIONARY:
				tag_name = str(tag.get("name", ""))
			else:
				tag_name = str(tag)
			if tag_name != "":
				shown.append(tag_name)
		if shown.size() > 0:
			text += "  |  " + shown.join(", ")
	return text


func _fmt_count(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 1000:
		return "%.1fk" % (value / 1000.0)
	return str(value)


func _tooltip_extra(mod: Dictionary) -> String:
	var parts := PoolStringArray()
	var updated = int(mod.get("date_updated", 0))
	if updated > 0:
		var date = OS.get_datetime_from_unix_time(updated)
		parts.append("Updated %04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)])
	var modfile = mod.get("modfile", {})
	if typeof(modfile) == TYPE_DICTIONARY:
		var size = int(modfile.get("filesize", 0))
		if size > 0:
			parts.append(_fmt_size(size))
	return "  |  ".join(parts)


func _fmt_size(value: int) -> String:
	if value >= 1048576:
		return "%.1f MB" % (value / 1048576.0)
	if value >= 1024:
		return "%.1f KB" % (value / 1024.0)
	return "%d B" % value


func _on_subscribe_pressed() -> void:
	emit_signal("subscribe_pressed", mod_id)


func _on_thumb_mouse_entered() -> void:
	var text = tooltip_text()
	if text == "":
		return
	emit_signal("description_hovered", mod_id, text, get_global_mouse_position())


func _on_thumb_mouse_exited() -> void:
	emit_signal("description_left", mod_id)


func _on_card_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_pressed = true
				_press_pos = event.position
			elif _pressed:
				_pressed = false
				emit_signal("open_pressed", mod_id)
		elif event.button_index == BUTTON_RIGHT and event.pressed:
			var text = tooltip_text()
			if text != "":
				emit_signal("description_clicked", mod_id, text, get_global_mouse_position())
	elif event is InputEventMouseMotion:
		if _pressed and event.position.distance_to(_press_pos) > DRAG_CANCEL_DISTANCE:
			_pressed = false
	elif event is InputEventScreenTouch:
		if event.pressed:
			_pressed = true
			_press_pos = event.position
		elif _pressed:
			_pressed = false
			emit_signal("open_pressed", mod_id)
	elif event is InputEventScreenDrag:
		if _pressed and event.position.distance_to(_press_pos) > DRAG_CANCEL_DISTANCE:
			_pressed = false


func _on_collections_pressed() -> void:
	emit_signal("collections_pressed", mod_id)


func _on_page_pressed() -> void:
	emit_signal("page_pressed", mod_id)
