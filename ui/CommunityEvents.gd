extends VBoxContainer
# Community events list shown on the main menu.
#
# On launch we render straight from the on-disk cache (instant, works offline),
# then fire a single request to the website for the live feed. Banners are cached
# per-event so repeated launches don't hammer the server. Each event is a 112x30
# image button with a description label underneath that smoothly expands on hover;
# clicking opens the event link in the Steam overlay.

const FEED_URL := "https://ivysly.com/hustle/announcements.json"
const CACHE_DIR := "user://community_events"
const CACHE_JSON := "user://community_events/feed.json"

const BANNER_SIZE := Vector2(112, 30)
const HOVER_TIME := 0.15
const SESSION_FLAG := "hustle_community_events_fetched"

onready var top_label := $TopLabel

var _feed_request: HTTPRequest
var _img_request: HTTPRequest
var _img_queue := []          # array of { "id", "url" }
var _rows := {}               # event id -> { "button", "label", "tween", "target_h" }
var _tween: Tween


func _ready() -> void:
	# Drop the scene's placeholder template nodes (TextureRect + Description) but
	# keep the "COMMUNITY EVENTS" TopLabel header — hidden until there are events.
	for child in get_children():
		if child != top_label:
			child.queue_free()
	top_label.visible = false

	_tween = Tween.new()
	add_child(_tween)

	var dir := Directory.new()
	if not dir.dir_exists(CACHE_DIR):
		dir.make_dir_recursive(CACHE_DIR)

	_feed_request = HTTPRequest.new()
	add_child(_feed_request)
	_feed_request.connect("request_completed", self, "_on_feed_received")

	_img_request = HTTPRequest.new()
	add_child(_img_request)
	_img_request.connect("request_completed", self, "_on_image_received")

	# 1) instant render from cache (cheap, offline-friendly, every time the menu opens)
	var cached := _load_cached_feed()
	if cached.size() > 0:
		_render(cached)

	# 2) refresh from the network at most ONCE per game session — the flag lives on the
	#    scene-tree root, which outlives this node if the menu UI is ever rebuilt.
	var root := get_tree().get_root()
	if not root.has_meta(SESSION_FLAG):
		root.set_meta(SESSION_FLAG, true)
		_feed_request.request(FEED_URL)  # HTTPRequest runs off the main thread

	# Panel visibility tracks the roadmap AND the "show community events" option.
	var roadmap := get_node_or_null("%RoadmapContainer")
	if roadmap != null:
		roadmap.connect("visibility_changed", self, "_apply_visibility")
	var events_toggle := get_node_or_null("%ShowCommunityEventsButton")
	if events_toggle != null:
		events_toggle.connect("toggled", self, "_on_events_toggle")
	_apply_visibility()


func _on_events_toggle(_pressed) -> void:
	_apply_visibility()


func _apply_visibility() -> void:
	var panel := get_parent()  # AnnouncementScrollContainer
	if panel == null:
		return
	var roadmap := get_node_or_null("%RoadmapContainer")
	var roadmap_visible = roadmap.visible if roadmap != null else true
	panel.visible = roadmap_visible and Global.show_community_events


# ---------------------------------------------------------------------------
# networking
# ---------------------------------------------------------------------------
func _on_feed_received(result: int, code: int, _headers: PoolStringArray, body: PoolByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return  # keep whatever the cache already rendered
	var text := body.get_string_from_utf8()
	var parsed = JSON.parse(text)
	if parsed.error != OK or not (parsed.result is Array):
		return
	_save_file(CACHE_JSON, body)
	_render(parsed.result)


func _on_image_received(result: int, code: int, _headers: PoolStringArray, body: PoolByteArray) -> void:
	var current = _img_queue.pop_front() if _img_queue.size() > 0 else null
	if current != null and result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var path := _img_path(current.id)
		_save_file(path, body)
		_apply_texture(current.id, _texture_from_png(body))
	_pump_image_queue()


func _pump_image_queue() -> void:
	if _img_queue.empty():
		return
	var next = _img_queue.front()
	var err := _img_request.request(next.url)
	if err != OK:
		_img_queue.pop_front()
		_pump_image_queue()


# ---------------------------------------------------------------------------
# rendering
# ---------------------------------------------------------------------------
func _render(events: Array) -> void:
	# tear down existing rows (the network feed supersedes the cached render)
	for id in _rows:
		_rows[id].button.get_parent().queue_free()
	_rows.clear()
	_img_request.cancel_request()  # drop any in-flight banner fetch from a prior render
	_img_queue.clear()

	top_label.visible = events.size() > 0

	for ev in events:
		if not (ev is Dictionary) or not ev.has("id"):
			continue
		_make_row(ev)
		# (re)fetch the banner; cached copy shows immediately meanwhile
		if ev.has("image"):
			_img_queue.append({"id": ev.id, "url": ev.image})

	_pump_image_queue()


func _make_row(ev: Dictionary) -> void:
	var row := VBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(row)

	var button := TextureButton.new()
	button.rect_min_size = BANNER_SIZE
	button.expand = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cached_tex = _load_cached_texture(ev.id)
	if cached_tex != null:
		button.texture_normal = cached_tex
	if ev.has("url"):
		button.connect("pressed", self, "_open_url", [ev.url])
	row.add_child(button)

	# Title (full opacity) above the description (faded) — RichTextLabel for the
	# two-tone colouring. Collapsed to 0 height until the button is hovered.
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.scroll_active = false
	rich.rect_min_size = Vector2(BANNER_SIZE.x, 0)
	rich.size_flags_horizontal = SIZE_FILL
	rich.bbcode_text = _row_bbcode(ev)
	row.add_child(rich)

	_rows[ev.id] = {"button": button, "rich": rich, "target_h": -1.0}

	button.connect("mouse_entered", self, "_expand_row", [ev.id])
	button.connect("mouse_exited", self, "_collapse_row", [ev.id])


func _row_bbcode(ev: Dictionary) -> String:
	# Opaque greys (no alpha) so the menu's brownish background doesn't bleed through.
	# Title slightly brighter than the description for hierarchy. Strip [ ] so event text
	# can't accidentally open bbcode tags.
	var title := str(ev.title).replace("[", "").replace("]", "") if ev.has("title") else ""
	var desc := str(ev.description).replace("[", "").replace("]", "") if ev.has("description") else ""
	return "[center][color=#dcdcdc]%s[/color]\n[color=#b1b1b1]%s[/color][/center]" % [title, desc]


func _expand_row(id) -> void:
	if not _rows.has(id):
		return
	var r = _rows[id]
	if r.target_h < 0:  # measure once, after the label has its real width
		r.target_h = r.rich.get_content_height()
	_tween_label(r.rich, r.target_h)


func _collapse_row(id) -> void:
	if not _rows.has(id):
		return
	_tween_label(_rows[id].rich, 0.0)


func _tween_label(label: Control, target_y: float) -> void:
	_tween.stop(label, "rect_min_size:y")
	_tween.interpolate_property(label, "rect_min_size:y", label.rect_min_size.y, target_y,
		HOVER_TIME, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	_tween.start()


func _apply_texture(id, tex) -> void:
	if tex != null and _rows.has(id):
		_rows[id].button.texture_normal = tex


func _open_url(url: String) -> void:
	if Steam.getAppID() != 0:
		Steam.activateGameOverlayToWebPage(url)
	else:
		OS.shell_open(url)


# ---------------------------------------------------------------------------
# cache helpers
# ---------------------------------------------------------------------------
func _img_path(id) -> String:
	return str(CACHE_DIR, "/", id, ".png")


func _load_cached_feed() -> Array:
	var f := File.new()
	if not f.file_exists(CACHE_JSON):
		return []
	f.open(CACHE_JSON, File.READ)
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse(text)
	if parsed.error == OK and parsed.result is Array:
		return parsed.result
	return []


func _load_cached_texture(id):
	var path := _img_path(id)
	var f := File.new()
	if not f.file_exists(path):
		return null
	f.open(path, File.READ)
	var bytes := f.get_buffer(f.get_len())
	f.close()
	return _texture_from_png(bytes)


func _texture_from_png(bytes: PoolByteArray):
	var img := Image.new()
	if img.load_png_from_buffer(bytes) != OK:
		return null
	var tex := ImageTexture.new()
	tex.create_from_image(img, 0)  # flags 0 = no filtering, crisp pixel art
	return tex


func _save_file(path: String, bytes: PoolByteArray) -> void:
	var f := File.new()
	if f.open(path, File.WRITE) == OK:
		f.store_buffer(bytes)
		f.close()
