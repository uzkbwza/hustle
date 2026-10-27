extends VBoxContainer

signal back_pressed
signal collections_pressed(mod_id)
signal homepage_pressed(url)
signal page_pressed(mod_id)
signal rate_pressed(mod_id, rating)
signal subscribe_pressed(mod_id)

const MODIO_IMAGE := preload("res://modloader/modio/ModIOImage.gd")
const IMAGE_MAX_SIZE := 1280

onready var back_btn: Button = $"%Back"
onready var title_label: Label = $"%Title"
onready var status_label: Label = $"%Status"
onready var logo: TextureRect = $"%Logo"
onready var name_label: Label = $"%Name"
onready var meta_label: Label = $"%Meta"
onready var summary_label: Label = $"%Summary"
onready var homepage_btn: Button = $"%Homepage"
onready var page_btn: Button = $"%Page"
onready var subscribe_btn: Button = $"%Subscribe"
onready var collections_btn: Button = $"%Collections"
onready var like_btn: Button = $"%Like"
onready var dislike_btn: Button = $"%Dislike"
onready var tags_label: Label = $"%Tags"
onready var description_label: Label = $"%Description"
onready var images_title: Label = $"%ImagesTitle"
onready var images_box: VBoxContainer = $"%Images"
onready var videos_title: Label = $"%VideosTitle"
onready var videos_box: VBoxContainer = $"%Videos"
onready var comments_title: Label = $"%CommentsTitle"
onready var comments_box: VBoxContainer = $"%Comments"

var mod_data := {}
var mod_id := ""
var subscribed := false
var signed_in := false
var installed := {}
var workshop := false
var vote := 0

var _image_queue := []
var _image_request: HTTPRequest = null
var _image_busy := false
var _image_cache := {}


func _ready() -> void:
	back_btn.connect("pressed", self, "_on_back_pressed")
	homepage_btn.connect("pressed", self, "_on_homepage_pressed")
	page_btn.connect("pressed", self, "_on_page_pressed")
	subscribe_btn.connect("pressed", self, "_on_subscribe_pressed")
	collections_btn.connect("pressed", self, "_on_collections_pressed")
	like_btn.connect("pressed", self, "_on_like_pressed")
	dislike_btn.connect("pressed", self, "_on_dislike_pressed")

	_image_request = HTTPRequest.new()
	add_child(_image_request)
	_image_request.use_threads = true
	_image_request.timeout = 20.0
	_image_request.connect("request_completed", self, "_on_image_received")


func open(mod: Dictionary) -> void:
	show()
	mod_data = mod
	mod_id = str(mod.get("id", ""))
	vote = 0
	set_status("")
	set_comments_status("Loading comments...")
	_render()


func show_mod(mod: Dictionary) -> void:
	if str(mod.get("id", "")) != mod_id:
		return
	mod_data = mod
	_render()


func set_subscribed(value: bool) -> void:
	subscribed = value
	_refresh_action_labels()


func set_signed_in(value: bool) -> void:
	signed_in = value
	_refresh_action_labels()


func set_workshop(value: bool) -> void:
	workshop = value
	homepage_btn.visible = not value
	collections_btn.visible = true
	like_btn.visible = true
	dislike_btn.visible = true
	page_btn.hint_tooltip = "Open this item on Steam" if value else "Open this mod's page on mod.io"
	_refresh_action_labels()


func set_vote(value: int) -> void:
	vote = value
	_refresh_action_labels()


func set_install_state(state: Dictionary) -> void:
	installed = state
	_render_meta()
	_refresh_action_labels()


func set_status(text: String) -> void:
	status_label.text = text
	status_label.visible = text != ""


func set_comments(comments: Array) -> void:
	_clear_children(comments_box)
	comments_title.visible = true
	if comments.empty():
		_add_note("No comments yet.")
		return
	for comment in comments:
		if typeof(comment) == TYPE_DICTIONARY:
			comments_box.add_child(_comment_entry(comment))


func set_comments_status(text: String) -> void:
	_clear_children(comments_box)
	comments_title.visible = true
	if text != "":
		_add_note(text)


func ui_elements() -> Array:
	return [back_btn, homepage_btn, page_btn, subscribe_btn, collections_btn, like_btn, dislike_btn]


func _render() -> void:
	if mod_data.empty():
		return
	title_label.text = str(mod_data.get("name", "Mod"))
	name_label.text = str(mod_data.get("name", ""))
	summary_label.text = str(mod_data.get("summary", "")).strip_edges()
	summary_label.visible = summary_label.text != ""

	var description = str(mod_data.get("description_plaintext", "")).strip_edges()
	if description == "":
		description = _strip_html(str(mod_data.get("description", ""))).strip_edges()
	if description == "":
		description = summary_label.text
	description_label.text = description

	_render_meta()
	_render_tags()
	_render_logo()
	_render_images()
	_render_videos()
	_refresh_action_labels()


func _render_meta() -> void:
	if mod_data.empty():
		return
	if workshop:
		_render_workshop_meta()
		return
	var author = "unknown"
	var submitted_by = mod_data.get("submitted_by", {})
	if typeof(submitted_by) == TYPE_DICTIONARY:
		author = str(submitted_by.get("display_name", submitted_by.get("username", "unknown")))

	var stats = mod_data.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		stats = {}

	var parts = PoolStringArray()
	parts.append("by " + author)
	parts.append(_fmt_count(int(stats.get("downloads_total", 0))) + " downloads")
	parts.append(_fmt_count(int(stats.get("subscribers_total", 0))) + " subscribers")
	var ratings = int(stats.get("ratings_total", 0))
	if ratings > 0:
		parts.append("%d%% positive (%d ratings)" % [
			int(stats.get("ratings_percentage_positive", 0)), ratings])
	else:
		parts.append("Not rated yet")
	var updated = int(mod_data.get("date_updated", 0))
	if updated > 0:
		parts.append("updated " + _format_date(updated))
	var modfile = mod_data.get("modfile", {})
	if typeof(modfile) == TYPE_DICTIONARY and int(modfile.get("filesize", 0)) > 0:
		parts.append(_fmt_size(int(modfile.get("filesize", 0))))
	if not installed.empty():
		if bool(installed.get("pending", false)):
			parts.append("queued for next launch")
		else:
			parts.append("installed")
	meta_label.text = "  |  ".join(parts)


func _render_workshop_meta() -> void:
	var parts := PoolStringArray()
	parts.append("by " + str(mod_data.get("workshop_author", "Steam user")))
	var size = int(mod_data.get("modfile", {}).get("filesize", 0))
	if size > 0:
		parts.append(_fmt_size(size))
	var up = int(mod_data.get("workshop_votes_up", 0))
	var down = int(mod_data.get("workshop_votes_down", 0))
	if up + down > 0:
		parts.append("%d%% positive (%d votes)" % [
			int(round(float(up) / float(up + down) * 100.0)), up + down])
	var updated = int(mod_data.get("date_updated", 0))
	if updated > 0:
		parts.append("updated " + _format_date(updated))
	var state = str(installed.get("workshop_state", ""))
	if state == "pending":
		parts.append("queued for next launch")
	elif state == "installed":
		parts.append("installed")
		if int(mod_data.get("workshop_time_updated", 0)) > int(installed.get("time_updated", 0)):
			parts.append("update available")
	meta_label.text = "  |  ".join(parts)


func _render_tags() -> void:
	var tags = mod_data.get("tags", [])
	var names = PoolStringArray()
	if typeof(tags) == TYPE_ARRAY:
		for tag in tags:
			var tag_name = ""
			if typeof(tag) == TYPE_DICTIONARY:
				tag_name = str(tag.get("name_localized", tag.get("name", "")))
			else:
				tag_name = str(tag)
			if tag_name != "":
				names.append(tag_name)
	tags_label.text = "Tags: " + names.join(", ") if names.size() > 0 else ""
	tags_label.visible = names.size() > 0


func _render_logo() -> void:
	var logo_data = mod_data.get("logo", {})
	if typeof(logo_data) != TYPE_DICTIONARY:
		logo_data = {}
	var url = str(logo_data.get("thumb_1280x720", ""))
	if url == "":
		url = str(logo_data.get("thumb_640x360", ""))
	if url == "":
		url = str(logo_data.get("thumb_320x180", ""))
	if url == "":
		url = str(logo_data.get("original", ""))
	logo.visible = url != ""
	if url != "":
		_queue_image(url, logo)


func _render_images() -> void:
	_clear_children(images_box)
	var media = mod_data.get("media", {})
	if typeof(media) != TYPE_DICTIONARY:
		media = {}
	var images = media.get("images", [])
	if typeof(images) != TYPE_ARRAY:
		images = []
	var count = 0
	for image in images:
		if typeof(image) != TYPE_DICTIONARY:
			continue
		var url = str(image.get("thumb_1280x720", ""))
		if url == "":
			url = str(image.get("original", ""))
		if url == "":
			url = str(image.get("thumb_320x180", ""))
		if url == "":
			continue
		var texture_rect = TextureRect.new()
		texture_rect.rect_min_size = Vector2(320, 180)
		texture_rect.size_flags_horizontal = SIZE_EXPAND_FILL
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		images_box.add_child(texture_rect)
		_queue_image(url, texture_rect)
		count += 1
	images_title.visible = count > 0
	images_box.visible = count > 0


func _render_videos() -> void:
	_clear_children(videos_box)
	var media = mod_data.get("media", {})
	if typeof(media) != TYPE_DICTIONARY:
		media = {}
	var videos = media.get("youtube", [])
	if typeof(videos) != TYPE_ARRAY:
		videos = []
	for url in videos:
		url = str(url)
		if url == "":
			continue
		var button = Button.new()
		button.size_flags_horizontal = SIZE_EXPAND_FILL
		button.hint_tooltip = "Open this video on YouTube"
		button.clip_text = true
		button.align = Button.ALIGN_LEFT
		button.text = url
		button.connect("pressed", self, "_on_video_pressed", [url])
		videos_box.add_child(button)
	var shown = videos_box.get_child_count() > 0
	videos_title.visible = shown
	videos_box.visible = shown


func _refresh_action_labels() -> void:
	if workshop:
		_refresh_workshop_labels()
		return
	like_btn.modulate = Color(1, 1, 1, 1)
	dislike_btn.modulate = Color(1, 1, 1, 1)
	var homepage = str(mod_data.get("homepage_url", ""))
	var profile = str(mod_data.get("profile_url", ""))
	homepage_btn.disabled = homepage == ""
	page_btn.disabled = profile == ""
	subscribe_btn.disabled = mod_id == ""
	collections_btn.disabled = mod_id == ""
	like_btn.disabled = mod_id == ""
	dislike_btn.disabled = mod_id == ""
	subscribe_btn.icon = MODIO_IMAGE.icon("unsubscribe") if subscribed else MODIO_IMAGE.icon("subscribe")
	if subscribed:
		subscribe_btn.hint_tooltip = "Unsubscribe from this mod and delete the download on next launch"
	elif not signed_in:
		subscribe_btn.hint_tooltip = "Sign in to mod.io to subscribe"
	else:
		subscribe_btn.hint_tooltip = "Subscribe to this mod and download it (installs on next launch)"


func _refresh_workshop_labels() -> void:
	page_btn.disabled = str(mod_data.get("profile_url", "")) == ""
	subscribe_btn.disabled = mod_id == ""
	collections_btn.disabled = mod_id == ""
	like_btn.disabled = mod_id == ""
	dislike_btn.disabled = mod_id == ""
	subscribe_btn.icon = MODIO_IMAGE.icon("unsubscribe") if subscribed else MODIO_IMAGE.icon("subscribe")
	if subscribed:
		subscribe_btn.hint_tooltip = "Unsubscribe and remove this item on next launch"
	else:
		subscribe_btn.hint_tooltip = "Subscribe and install this item (installs on next launch)"
	like_btn.modulate = Color(1, 1, 1, 1) if vote == 1 else Color(0.7, 0.7, 0.7, 1)
	dislike_btn.modulate = Color(1, 1, 1, 1) if vote == -1 else Color(0.7, 0.7, 0.7, 1)
	like_btn.hint_tooltip = "You liked this item" if vote == 1 else "Like this item"
	dislike_btn.hint_tooltip = "You disliked this item" if vote == -1 else "Dislike this item"


func _add_note(text: String) -> void:
	var label = Label.new()
	label.modulate = Color(0.75, 0.75, 0.75)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.autowrap = true
	label.text = text
	comments_box.add_child(label)


func _comment_entry(comment: Dictionary) -> Label:
	var label = Label.new()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.autowrap = true
	var user = comment.get("user", {})
	var author = "unknown"
	if typeof(user) == TYPE_DICTIONARY:
		author = str(user.get("display_name", user.get("username", "unknown")))
	var header = author
	var added = int(comment.get("date_added", 0))
	if added > 0:
		header += "  |  " + _format_date(added)
	var text = _strip_html(str(comment.get("content", ""))).strip_edges()
	label.text = header + "\n" + text
	return label


func _format_date(value: int) -> String:
	var date = OS.get_datetime_from_unix_time(value)
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]


func _fmt_count(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 1000:
		return "%.1fk" % (value / 1000.0)
	return str(value)


func _fmt_size(value: int) -> String:
	if value >= 1048576:
		return "%.1f MB" % (value / 1048576.0)
	if value >= 1024:
		return "%.1f KB" % (value / 1024.0)
	return "%d B" % value


func _strip_html(text: String) -> String:
	var regex = RegEx.new()
	if regex.compile("<[^>]*>") != OK:
		return text
	return regex.sub(text, "", true)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _queue_image(url: String, target: TextureRect) -> void:
	if _image_cache.has(url):
		target.texture = _image_cache[url]
		return
	for entry in _image_queue:
		if str(entry["url"]) == url:
			entry["targets"].append(weakref(target))
			return
	_image_queue.append({"url": url, "targets": [weakref(target)]})
	_pump_images()


func _pump_images() -> void:
	if _image_busy or _image_queue.empty():
		return
	var entry = _image_queue.front()
	if not ModIO.is_allowed_image_url(str(entry["url"])) \
	or _image_request.request(str(entry["url"])) != OK:
		_image_queue.pop_front()
		_pump_images()
		return
	_image_busy = true


func _on_image_received(result, code, _headers, body) -> void:
	_image_busy = false
	var entry = _image_queue.pop_front() if _image_queue.size() > 0 else null
	if entry != null and result == HTTPRequest.RESULT_SUCCESS and code == 200 \
	and body.size() <= ModIO.MAX_IMAGE_BYTES:
		var texture = MODIO_IMAGE.texture_from_bytes(body, IMAGE_MAX_SIZE)
		if texture != null:
			_image_cache[str(entry["url"])] = texture
			for reference in entry["targets"]:
				var target = reference.get_ref()
				if target != null and is_instance_valid(target):
					target.texture = texture
	_pump_images()


func _on_back_pressed() -> void:
	emit_signal("back_pressed")


func _on_homepage_pressed() -> void:
	emit_signal("homepage_pressed", str(mod_data.get("homepage_url", "")))


func _on_page_pressed() -> void:
	emit_signal("page_pressed", mod_id)


func _on_subscribe_pressed() -> void:
	emit_signal("subscribe_pressed", mod_id)


func _on_collections_pressed() -> void:
	emit_signal("collections_pressed", mod_id)


func _on_like_pressed() -> void:
	emit_signal("rate_pressed", mod_id, 1)


func _on_dislike_pressed() -> void:
	emit_signal("rate_pressed", mod_id, -1)


func _on_video_pressed(url: String) -> void:
	ModIO.open_web_url(url)
