extends Node

const RES_CONFIG := "res://modloader/modio/modio.cfg"
const USER_CONFIG := "user://modio.cfg"
const INSTALLED_DB := "user://modio_installed.json"
const CACHE_DIR := "user://modio_cache"

const DEFAULT_GAME_ID := 14399
const DEFAULT_WEB_URL := "https://mod.io/g/youronlymoveishustle"
const DEFAULT_WEB_PORTAL := "steam"

const MAX_REDIRECTS := 5
const JSON_CACHE_TTL_MS := 5000
const MAX_JSON_BYTES := 4 * 1024 * 1024
const MAX_IMAGE_BYTES := 12 * 1024 * 1024
const MAX_DOWNLOAD_BYTES := 4 * 1024 * 1024 * 1024
const MAX_URL_LENGTH := 2048

var game_id := 0
var api_key := ""
var web_url := ""
var web_portal := ""
var base_url := ""
var use_test_environment := false

var _installed := {}
var _installed_loaded := false
var _json_cache := {}
var _json_inflight := {}
var _download_queue := []
var _active_download = null
var _boundary_counter := 0


func _ready() -> void:
	var values := {}
	values.merge(_read_config(RES_CONFIG))
	values.merge(_read_config(USER_CONFIG), true)

	game_id = int(values.get("game_id", DEFAULT_GAME_ID))
	api_key = str(values.get("api_key", "")).strip_edges()
	web_url = str(values.get("web_url", DEFAULT_WEB_URL))
	web_portal = str(values.get("web_portal", DEFAULT_WEB_PORTAL))
	use_test_environment = bool(values.get("use_test_environment", false))
	base_url = ("https://g-%d.test.mod.io/v1" if use_test_environment
		else "https://g-%d.modapi.io/v1") % game_id

	_ensure_dir(CACHE_DIR)
	_ensure_installed_loaded()


func is_configured() -> bool:
	return game_id > 0 and api_key != ""


func is_allowed_url(url: String) -> bool:
	var host = _safe_url_host(url)
	if host == "":
		return false
	return host == "mod.io" or host.ends_with(".mod.io") \
		or host == "modapi.io" or host.ends_with(".modapi.io")


# Artwork lives on mod.io's CDN (image.modcdn.io, thumb.modcdn.io) and, for
# Steam Workshop items, on Steam's image hosts. Only used for images: requests
# that carry the account token or download a file keep using is_allowed_url.
func is_allowed_image_url(url: String) -> bool:
	var host = _safe_url_host(url)
	if host == "":
		return false
	if is_allowed_url(url):
		return true
	return host == "modcdn.io" or host.ends_with(".modcdn.io") \
		or host == "steamusercontent.com" or host.ends_with(".steamusercontent.com") \
		or host == "steamuserimages-a.akamaihd.net" \
		or host == "steamcdn-a.akamaihd.net" \
		or host == "cdn.akamai.steamstatic.com"


# Returns the URL's host, or "" when the URL isn't a plain https address with
# no credentials, port, control characters or ".." in the path.
func _safe_url_host(url: String) -> String:
	if url == "" or url.length() > MAX_URL_LENGTH:
		return ""
	for index in url.length():
		var code = url.ord_at(index)
		if code < 32 or code == 127:
			return ""
	if not url.to_lower().begins_with("https://"):
		return ""
	var rest = url.substr(8)
	var slash = rest.find("/")
	var host = rest if slash == -1 else rest.substr(0, slash)
	if host == "" or host.find("@") != -1 or host.find(":") != -1:
		return ""
	if slash != -1 and rest.substr(slash).find("..") != -1:
		return ""
	return host


func get_write_base_url() -> String:
	return base_url


func _read_config(path: String) -> Dictionary:
	var cfg = ConfigFile.new()
	if cfg.load(path) != OK:
		return {}
	var result := {}
	for key in ["game_id", "api_key", "web_url", "web_portal", "use_test_environment"]:
		if cfg.has_section_key("modio", key):
			result[key] = cfg.get_value("modio", key)
	return result


func get_json(path: String, params: Dictionary = {}, target: Object = null,
		callback: String = "", binds: Array = []) -> void:

	var url = _build_url(path, params)
	var pending = {"target": target, "callback": callback, "binds": binds}
	if url == "":
		_deliver_json(pending, null, 0)
		return
	var cached = _json_cache.get(url, {})
	if typeof(cached) == TYPE_DICTIONARY \
	and OS.get_ticks_msec() - int(cached.get("time", 0)) < JSON_CACHE_TTL_MS:
		_deliver_json(pending, cached.get("data"), int(cached.get("code", 200)))
		return
	if _json_inflight.has(url):
		_json_inflight[url].append(pending)
		return
	_json_inflight[url] = [pending]

	var req = HTTPRequest.new()
	add_child(req)
	req.use_threads = true
	req.timeout = 20.0
	req.connect("request_completed", self, "_on_get_json_completed", [req, url])

	var err = req.request(url)
	if err != OK:
		_json_inflight.erase(url)
		req.queue_free()
		_deliver_json(pending, null, 0)


func _deliver_json(pending: Dictionary, parsed, code: int) -> void:
	var target = pending.get("target")
	if target != null and is_instance_valid(target):
		target.call(pending.callback, parsed, code, pending.binds)


func _on_get_json_completed(result, code, _headers, body, req, url) -> void:
	req.queue_free()
	var parsed = null
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and body.size() <= MAX_JSON_BYTES:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			parsed = json.result
	if parsed != null:
		_json_cache[url] = {"time": OS.get_ticks_msec(), "data": parsed, "code": code}
	var pending = _json_inflight.get(url, [])
	_json_inflight.erase(url)
	for waiter in pending:
		_deliver_json(waiter, parsed, code)


func _on_authed_get_json_completed(result, code, _headers, body, req, target, callback, binds) -> void:
	req.queue_free()
	var parsed = null
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and body.size() <= MAX_JSON_BYTES:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			parsed = json.result
	if target != null and is_instance_valid(target):
		target.call(callback, parsed, code, binds)


func request_game(target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d" % game_id, {}, target, callback, binds)


func request_mods_page(params: Dictionary, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/mods" % game_id, params, target, callback, binds)


func request_collections_page(params: Dictionary, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/collections" % game_id, params, target, callback, binds)


func request_guides_page(params: Dictionary, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/guides" % game_id, params, target, callback, binds)


func request_mod_collections(mod_id: int, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/mods/%d/collections" % [game_id, mod_id], {"limit": 100}, target, callback, binds)


func request_mod(mod_id: int, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/mods/%d" % [game_id, mod_id], {}, target, callback, binds)


func request_mod_comments(mod_id: int, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/mods/%d/comments" % [game_id, mod_id],
		{"_sort": "-date_added", "limit": 50}, target, callback, binds)


func request_tag_options(target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/tags" % game_id, {}, target, callback, binds)


func request_guide_tags(target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/guides/tags" % game_id, {}, target, callback, binds)


func request_subscribed(offset: int, limit: int, target: Object, callback: String, binds: Array = []) -> void:
	_authed_get_json("me/subscribed", {"game_id": game_id, "offset": offset, "limit": limit},
		target, callback, binds)


func request_subscribed_page(params: Dictionary, target: Object, callback: String, binds: Array = []) -> void:
	var query = {"game_id": game_id}
	query.merge(params, true)
	_authed_get_json("me/subscribed", query, target, callback, binds)


func request_collections(target: Object, callback: String, binds: Array = []) -> void:
	_authed_get_json("me/collections", {}, target, callback, binds)


func request_collection_mods(collection_id: int, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/collections/%d/mods" % [game_id, collection_id], {"limit": 100}, target, callback, binds)


func set_subscription(mod_id: int, subscribed: bool, target: Object, callback: String, binds: Array = []) -> void:
	var token = _auth_token()
	if token == "":
		_authed_callback(target, callback, binds)
		return
	var url = "%s/games/%d/mods/%d/subscribe" % [get_write_base_url(), game_id, mod_id]
	var method = HTTPClient.METHOD_POST if subscribed else HTTPClient.METHOD_DELETE
	_authed_raw_request(url, method, PoolByteArray(), "", token, target, callback, binds)


func set_mod_rating(mod_id: int, rating: int, target: Object, callback: String, binds: Array = []) -> void:
	var token = _auth_token()
	if token == "":
		_authed_callback(target, callback, binds)
		return
	var value = 1 if rating > 0 else -1
	var url = "%s/games/%d/mods/%d/ratings" % [get_write_base_url(), game_id, mod_id]
	_authed_raw_request(url, HTTPClient.METHOD_POST, ("rating=" + str(value)).to_utf8(),
		"application/x-www-form-urlencoded", token, target, callback, binds)


func create_collection(title: String, mod_ids: Array, target: Object, callback: String, binds: Array = []) -> void:
	var token = _auth_token()
	if token == "":
		_authed_callback(target, callback, binds)
		return
	var multipart = ModIOUploadAPI.new_multipart(_new_boundary())
	ModIOUploadAPI.multipart_field(multipart, "name", title)
	ModIOUploadAPI.multipart_field(multipart, "summary", "Mod list created in-game")
	ModIOUploadAPI.multipart_field(multipart, "description", "")
	ModIOUploadAPI.multipart_field(multipart, "visible", "0")
	ModIOUploadAPI.multipart_field(multipart, "collection_tags", "")
	for mod_id in mod_ids:
		ModIOUploadAPI.multipart_field(multipart, "mod_ids[]", str(mod_id))
	var logo_path = _collection_logo_path()
	if logo_path != "":
		ModIOUploadAPI.multipart_file(multipart, "logo", logo_path, "image/png")
	var url = "%s/games/%d/collections" % [get_write_base_url(), game_id]
	_authed_raw_request(url, HTTPClient.METHOD_POST, ModIOUploadAPI.multipart_finish(multipart),
		"multipart/form-data; boundary=" + multipart.boundary, token, target, callback, binds)


func _collection_logo_path() -> String:
	var path = CACHE_DIR.plus_file("collection_logo.png")
	var f = File.new()
	if f.file_exists(path):
		return path
	var image = Image.new()
	image.create(1280, 720, false, Image.FORMAT_RGBA8)
	var top = Color("#262b36")
	var bottom = Color("#101218")
	for y in range(0, 720, 2):
		image.fill_rect(Rect2(0, y, 1280, 2), top.linear_interpolate(bottom, y / 720.0))
	image.fill_rect(Rect2(96, 300, 1088, 6), Color("#e8a33c"))
	image.fill_rect(Rect2(96, 336, 620, 6), Color("#3b4252"))
	if image.save_png(path) != OK:
		return ""
	return path


func add_collection_mod(collection_id: int, mod_ids: Array, target: Object, callback: String, binds: Array = []) -> void:
	var token = _auth_token()
	if token == "":
		_authed_callback(target, callback, binds)
		return
	var multipart = ModIOUploadAPI.new_multipart(_new_boundary())
	for mod_id in mod_ids:
		ModIOUploadAPI.multipart_field(multipart, "mod_ids[]", str(mod_id))
	var url = "%s/games/%d/collections/%d" % [get_write_base_url(), game_id, collection_id]
	_authed_raw_request(url, HTTPClient.METHOD_POST, ModIOUploadAPI.multipart_finish(multipart),
		"multipart/form-data; boundary=" + multipart.boundary, token, target, callback, binds)


func remove_collection_mod(collection_id: int, mod_ids: Array, target: Object, callback: String, binds: Array = []) -> void:
	var token = _auth_token()
	if token == "":
		_authed_callback(target, callback, binds)
		return
	var body := ""
	for mod_id in mod_ids:
		if body != "":
			body += "&"
		body += "mod_ids[]=" + str(mod_id).http_escape()
	var url = "%s/games/%d/collections/%d/mods" % [get_write_base_url(), game_id, collection_id]
	_authed_raw_request(url, HTTPClient.METHOD_DELETE, body.to_utf8(),
		"application/x-www-form-urlencoded", token, target, callback, binds)


func delete_collection(collection_id: int, target: Object, callback: String, binds: Array = []) -> void:
	var token = _auth_token()
	if token == "":
		_authed_callback(target, callback, binds)
		return
	var url = "%s/games/%d/collections/%d" % [get_write_base_url(), game_id, collection_id]
	_authed_raw_request(url, HTTPClient.METHOD_DELETE, PoolByteArray(), "", token, target, callback, binds)


func _auth_token() -> String:
	return ModIOAuth.get_access_token()


func _authed_callback(target: Object, callback: String, binds: Array) -> void:
	if target != null and is_instance_valid(target):
		target.call(callback, null, 401, binds)


func _authed_get_json(path: String, params: Dictionary, target: Object, callback: String, binds: Array) -> void:
	var token := _auth_token()
	if token == "":
		_authed_callback(target, callback, binds)
		return
	var url := _build_url(path, params)
	if url == "":
		_authed_callback(target, callback, binds)
		return
	var req = HTTPRequest.new()
	add_child(req)
	req.use_threads = true
	req.timeout = 20.0
	req.connect("request_completed", self, "_on_authed_get_json_completed", [req, target, callback, binds])

	var headers = PoolStringArray([
		"Authorization: Bearer " + token,
		"Accept: application/json",
		"Origin: https://mod.io",
	])
	if req.request(url, headers) != OK:
		req.queue_free()
		_authed_callback(target, callback, binds)


func _authed_raw_request(url: String, method: int, body: PoolByteArray, content_type: String,
		token: String, target: Object, callback: String, binds: Array) -> void:

	if not is_allowed_url(url):
		_authed_callback(target, callback, binds)
		return
	var req = HTTPRequest.new()
	add_child(req)
	req.use_threads = true
	req.timeout = 30.0
	req.connect("request_completed", self, "_on_authed_request_completed", [req, target, callback, binds])

	var headers = PoolStringArray([
		"Authorization: Bearer " + token,
		"Accept: application/json",
		"Origin: https://mod.io",
	])
	if content_type == "" and method != HTTPClient.METHOD_GET:
		content_type = "application/x-www-form-urlencoded"
	if content_type != "":
		headers.append("Content-Type: " + content_type)

	var err = req.request_raw(url, headers, true, method, body)
	if err != OK:
		req.queue_free()
		_authed_callback(target, callback, binds)


func _on_authed_request_completed(result, code, _headers, body, req, target, callback, binds) -> void:
	req.queue_free()
	var parsed = null
	if result == HTTPRequest.RESULT_SUCCESS and code != 204 and body.size() > 0 \
	and body.size() <= MAX_JSON_BYTES:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK:
			parsed = json.result
	if target != null and is_instance_valid(target):
		target.call(callback, parsed, code, binds)


func _new_boundary() -> String:
	_boundary_counter += 1
	return "----ModIOBoundary" + str(OS.get_ticks_msec()) + "_" + str(_boundary_counter)


func request_mod_files(mod_id: int, target: Object, callback: String, binds: Array = []) -> void:
	get_json("games/%d/mods/%d/files" % [game_id, mod_id], {"_sort": "-date_added"}, target, callback, binds)


func request_modfile_download_url(mod_id: int, file_id: int, target: Object,
		callback: String, binds: Array = []) -> void:

	get_json("games/%d/mods/%d/files/%d" % [game_id, mod_id, file_id], {}, target, callback, binds)


func _build_url(path: String, params: Dictionary = {}) -> String:
	var clean_path = path.strip_edges()
	if clean_path == "" or clean_path.begins_with("/") or clean_path.find("://") != -1 \
	or clean_path.find("..") != -1:
		return ""
	var query = "api_key=" + api_key.http_escape()
	for key in params:
		var value = str(params[key])
		if value == "":
			continue
		query += "&" + str(key) + "=" + value.http_escape()
	return base_url + "/" + clean_path + "?" + query


func download(url: String, dest: String, target: Object, callback: String,
		binds: Array = [], total_bytes: int = 0) -> void:

	if not is_allowed_url(url) or not _is_safe_download_dest(dest):
		if target != null and is_instance_valid(target):
			target.call(callback, false, "Download blocked: untrusted source", binds)
		return
	if total_bytes > MAX_DOWNLOAD_BYTES:
		if target != null and is_instance_valid(target):
			target.call(callback, false, "Download blocked: file too large", binds)
		return

	_download_queue.append({
		"url": url,
		"dest": dest,
		"target": target,
		"callback": callback,
		"binds": binds,
		"total_bytes": total_bytes,
		"req": null,
	})
	_pump_downloads()


func _pump_downloads() -> void:
	if _active_download != null or _download_queue.empty():
		return
	var job = _download_queue.pop_front()
	_active_download = job

	job.req = HTTPRequest.new()
	add_child(job.req)
	job.req.use_threads = true
	job.req.timeout = 120.0
	job.req.max_redirects = MAX_REDIRECTS
	job.req.download_file = job.dest
	job.req.connect("request_completed", self, "_on_download_completed", [job])

	var err = job.req.request(job.url)
	if err != OK:
		job.req.queue_free()
		_finish_job(job, false, "Could not start download (error %d)" % err)


func _on_download_completed(result, code, _headers, _body, job) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var size = _file_size(job.dest)
		var too_large = size > MAX_DOWNLOAD_BYTES
		var wrong_size = job.total_bytes > 0 and size != job.total_bytes
		if size < 0 or too_large or wrong_size:
			_delete_file(job.dest)
			_finish_job(job, false, "Download was incomplete")
			return
		_finish_job(job, true, job.dest)
		return

	_delete_file(job.dest)
	if result != HTTPRequest.RESULT_SUCCESS:
		_finish_job(job, false, "Download failed (network error %d)" % result)
	else:
		_finish_job(job, false, "Download failed (HTTP %d)" % code)


func _finish_job(job, ok: bool, payload) -> void:
	if job.req != null and is_instance_valid(job.req):
		job.req.queue_free()
	_active_download = null
	if job.target != null and is_instance_valid(job.target):
		job.target.call(job.callback, ok, payload, job.binds)
	_pump_downloads()


func get_downloaded_bytes() -> int:
	if _active_download == null:
		return -1
	var req = _active_download.req
	if req == null or not is_instance_valid(req):
		return -1
	return req.get_downloaded_bytes()


func get_installed(mod_id) -> Dictionary:
	_ensure_installed_loaded()
	return _installed.get(str(mod_id), {})


func record_installed(mod_id, info: Dictionary) -> void:
	_ensure_installed_loaded()
	FileManager.unmark_for_deletion(str(info.get("path", "")))
	_installed[str(mod_id)] = info
	_save_installed()


func queue_uninstall(mod_id) -> void:
	_ensure_installed_loaded()
	var info = get_installed(mod_id)
	if info.has("path"):
		FileManager.mark_for_deletion(PoolStringArray([str(info.path)]))
	_installed.erase(str(mod_id))
	_save_installed()


func reconcile_installed() -> void:
	_ensure_installed_loaded()
	var changed := false
	for key in _installed.keys():
		var info = _installed[key]
		var path = ""
		if typeof(info) == TYPE_DICTIONARY:
			path = str(info.get("path", ""))
		if path == "" or not File.new().file_exists(path):
			_installed.erase(key)
			changed = true
	if changed:
		_save_installed()


func _ensure_installed_loaded() -> void:
	if _installed_loaded:
		return
	_installed_loaded = true
	_installed = _load_installed()


func _load_installed() -> Dictionary:
	var f = File.new()
	if not f.file_exists(INSTALLED_DB):
		return {}
	if f.open(INSTALLED_DB, File.READ) != OK:
		return {}
	var parsed = JSON.parse(f.get_as_text())
	f.close()
	if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
		return parsed.result
	return {}


func _save_installed() -> void:
	var f = File.new()
	if f.open(INSTALLED_DB, File.WRITE) == OK:
		f.store_string(JSON.print(_installed, "  ", true))
		f.close()


func get_mods_dir() -> String:
	return WORKSHOP_STORE.mods_dir()


func open_web_url(url: String) -> void:
	if not is_allowed_url(url):
		return
	if web_portal != "":
		url += ("&" if "?" in url else "?") + "portal=" + web_portal
	var external = url.find("mod.io/terms") != -1 or url.find("mod.io/privacy") != -1
	if not external and Steam.getAppID() != 0:
		Steam.activateGameOverlayToWebPage(url)
	else:
		OS.shell_open(url)


func _ensure_dir(path: String) -> void:
	var dir = Directory.new()
	if not dir.dir_exists(path):
		dir.make_dir_recursive(path)


func _delete_file(path: String) -> void:
	if path == "":
		return
	var global_path = ProjectSettings.globalize_path(path)
	var dir = Directory.new()
	if dir.file_exists(global_path):
		dir.remove(global_path)


func _file_size(path: String) -> int:
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return -1
	var size = file.get_len()
	file.close()
	return size


func _is_safe_download_dest(path: String) -> bool:
	if path == "":
		return false
	var clean = path.replace("\\", "/")
	if clean.find("..") != -1:
		return false
	if clean.get_file() == "" or clean.get_file().begins_with("."):
		return false
	if clean.begins_with("user://"):
		return true
	var mods_dir = get_mods_dir().replace("\\", "/").simplify_path().trim_suffix("/")
	var target = clean.simplify_path()
	return mods_dir != "" and target.begins_with(mods_dir + "/")


signal issues_changed(issues)

const WORKSHOP_API := preload("res://modloader/modio/WorkshopAPI.gd")
const WORKSHOP_STORE := preload("res://modloader/modio/WorkshopStore.gd")

const STEAM_STATE_SUBSCRIBED := 1
const STEAM_STATE_INSTALLED := 4
const STEAM_STATE_NEEDS_UPDATE := 8
const STEAM_TOKEN := 1001
const STEAM_PAGE_SIZE := 50
const MODIO_PAGE_SIZE := 100

var issues := {}
var _dismissed := {}
var _checked := false

var _workshop = null
var _steam_items := {}
var _steam_offset := 0
var _steam_total := 0
var _modio_offset := 0
var _modio_total := 0
var _modio_subscribed := {}


func check() -> void:
	if _checked:
		_emit()
		return
	_checked = true
	_check_steam()
	_check_modio()


func dismiss_keys(keys: Array) -> void:
	for key in keys:
		_dismissed[str(key)] = true


func update_issue(key: String) -> void:
	var issue = issues.get(key, {})
	if issue.empty() or issue.get("busy", false) or issue.get("resolved", false):
		return
	issue["busy"] = true
	_emit()
	if issue.source == "steam":
		if not _ensure_workshop():
			_finish_issue(key, "Steam Workshop is not available.")
			return
		_set_status(key, "Starting download...")
		_workshop.install(int(issue.id), issue.meta)
	else:
		_set_status(key, "Looking up the latest file...")
		ModIO.request_mod_files(int(issue.id), self, "_on_modio_files", [key])


func unsubscribe_issue(key: String) -> void:
	var issue = issues.get(key, {})
	if issue.empty() or issue.get("busy", false):
		return
	issue["busy"] = true
	_emit()
	if issue.source == "steam":
		if not _ensure_workshop():
			_finish_issue(key, "Steam Workshop is not available.")
			return
		_workshop.uninstall(int(issue.id))
		_remove_issue(key)
	else:
		_modio_cancel_issue(key, int(issue.id))


func _check_steam() -> void:
	if not _ensure_workshop():
		_finish_steam()
		return
	_steam_items.clear()
	_steam_offset = 0
	_steam_total = 0
	_request_steam_page()


func _ensure_workshop() -> bool:
	if _workshop != null and is_instance_valid(_workshop):
		return true
	var api = WORKSHOP_API.new()
	if not api.is_available():
		api.free()
		return false
	add_child(api)
	_workshop = api
	_workshop.connect("browse_loaded", self, "_on_steam_loaded")
	_workshop.connect("browse_failed", self, "_on_steam_failed")
	_workshop.connect("install_started", self, "_on_steam_install_started")
	_workshop.connect("install_progress", self, "_on_steam_install_progress")
	_workshop.connect("install_finished", self, "_on_steam_install_finished")
	_workshop.connect("install_failed", self, "_on_steam_install_failed")
	_workshop.connect("removed", self, "_on_steam_removed")
	_workshop.refresh_subscriptions()
	return true


func _request_steam_page() -> void:
	_workshop.request_subscribed("subscription", _steam_offset, STEAM_TOKEN)


func _on_steam_loaded(items, total, token) -> void:
	if int(token) != STEAM_TOKEN:
		return
	_steam_total = int(total)
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and item.has("id"):
			_steam_items[str(item.id)] = item
	_steam_offset += STEAM_PAGE_SIZE
	if items.size() > 0 and _steam_offset < _steam_total:
		_request_steam_page()
	else:
		_finish_steam()


func _on_steam_failed(message, token) -> void:
	if int(token) != STEAM_TOKEN:
		return
	print("Workshop subscription check failed: " + str(message))
	_finish_steam()


func _finish_steam() -> void:
	if _workshop == null or not is_instance_valid(_workshop):
		_emit()
		return
	var ids := {}
	var subscribed = Steam.getSubscribedItems()
	if subscribed != null:
		for item in subscribed:
			ids[str(item)] = true
	var entries = WORKSHOP_STORE.load_db()
	for key in entries.keys():
		ids[str(key)] = true
	var id_list = ids.keys()
	id_list.sort()
	for item_id in id_list:
		var issue = _steam_issue(str(item_id), _steam_items.get(str(item_id), {}), entries)
		if not issue.empty():
			issues[issue.key] = issue
	_emit()


func _steam_issue(item_id: String, item: Dictionary, entries: Dictionary) -> Dictionary:
	var entry = entries.get(item_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		entry = {}
	if str(entry.get("state", "")) == "pending":
		return {}

	var title = str(entry.get("title", ""))
	if title == "":
		title = str(item.get("name", ""))
	if title == "":
		title = "Workshop item " + item_id

	var author = str(entry.get("author", ""))
	if author == "":
		author = str(item.get("workshop_author", "Steam user"))

	var issue = {
		"key": "steam:" + item_id,
		"source": "steam",
		"source_label": "Steam Workshop",
		"id": item_id,
		"title": title,
		"author": author,
		"status": "",
		"busy": false,
		"resolved": false,
		"meta": _steam_meta(item, title, author),
	}

	var steam_owned = str(entry.get("source", "")) == "steam"
	if not entry.empty() and not steam_owned and WORKSHOP_STORE.has_local_copies(entry):
		if not _entry_files_exist(entry):
			issue["state"] = "missing"
			issue["status"] = "The installed files are missing"
			return issue
		var remote_time = int(item.get("workshop_time_updated", 0))
		if remote_time > int(entry.get("time_updated", 0)):
			issue["state"] = "update"
			issue["status"] = "An update is available"
			return issue
		return {}

	var state = int(Steam.getItemState(int(item_id)))
	if (state & STEAM_STATE_SUBSCRIBED) == 0:
		issue["state"] = "missing"
		issue["status"] = "Not subscribed"
		return issue
	if (state & STEAM_STATE_NEEDS_UPDATE) != 0:
		issue["state"] = "update"
		issue["status"] = "Steam needs to update it"
		return issue
	if (state & STEAM_STATE_INSTALLED) == 0:
		issue["state"] = "missing"
		issue["status"] = "Not downloaded"
		return issue
	return {}


func _steam_meta(item: Dictionary, title: String, author: String) -> Dictionary:
	var preview_url = ""
	var logo = item.get("logo", {})
	if typeof(logo) == TYPE_DICTIONARY:
		preview_url = str(logo.get("thumb_320x180", logo.get("original", "")))
	var meta = {
		"title": title,
		"author": author,
		"preview_url": preview_url,
	}
	var updated = int(item.get("workshop_time_updated", 0))
	if updated > 0:
		meta["time_updated"] = updated
	return meta


func _entry_files_exist(entry: Dictionary) -> bool:
	var found_any := false
	for key in ["mods", "styles"]:
		var files = entry.get(key, [])
		if typeof(files) != TYPE_ARRAY:
			continue
		for path in files:
			found_any = true
			if not File.new().file_exists(str(path)):
				return false
	return found_any


func _check_modio() -> void:
	if not ModIO.is_configured() or not ModIOAuth.is_logged_in():
		_emit()
		return
	_modio_offset = 0
	_modio_total = 0
	_modio_subscribed.clear()
	_request_modio_page()


func _request_modio_page() -> void:
	ModIO.request_subscribed(_modio_offset, MODIO_PAGE_SIZE, self, "_on_modio_loaded")


func _on_modio_loaded(parsed, _code, _binds) -> void:
	var received := 0
	var page_ok := false
	if parsed != null and typeof(parsed) == TYPE_DICTIONARY:
		var mods = parsed.get("data", [])
		if typeof(mods) == TYPE_ARRAY:
			page_ok = true
			received = mods.size()
			var pending = WORKSHOP_STORE.modio_pending()
			for mod in mods:
				if typeof(mod) != TYPE_DICTIONARY:
					continue
				var item_id = str(mod.get("id", ""))
				if item_id != "":
					_modio_subscribed[item_id] = true
				var issue = _modio_issue(mod, pending)
				if not issue.empty():
					issues[issue.key] = issue
			_modio_total = int(parsed.get("result_total", 0))
	_modio_offset += MODIO_PAGE_SIZE
	if page_ok and received > 0 and _modio_offset < _modio_total:
		_request_modio_page()
	else:
		if page_ok and _modio_offset >= _modio_total:
			_reconcile_modio_subscriptions()
		_emit()


func _reconcile_modio_subscriptions() -> void:
	var user_id := int(ModIOAuth.user_id)
	if user_id <= 0:
		return
	_ensure_installed_loaded()
	var stale := []
	for key in _installed.keys():
		if _modio_subscribed.has(str(key)):
			continue
		var info = _installed[key]
		if typeof(info) != TYPE_DICTIONARY:
			continue
		var owner := int(info.get("user_id", 0))
		if owner != 0 and owner != user_id:
			continue
		stale.append(str(key))
	for key in stale:
		print("mod.io: removing unsubscribed mod " + str(key))
		queue_uninstall(key)
	var pending = WORKSHOP_STORE.modio_pending()
	for key in pending.keys():
		if not _modio_subscribed.has(str(key)):
			WORKSHOP_STORE.modio_discard(key)


func _modio_issue(mod: Dictionary, pending: Dictionary) -> Dictionary:
	var item_id = str(mod.get("id", ""))
	if item_id == "":
		return {}

	var title = str(mod.get("name", ""))
	if title == "":
		title = "mod.io mod " + item_id
	var author := "mod.io user"
	var submitted_by = mod.get("submitted_by", {})
	if typeof(submitted_by) == TYPE_DICTIONARY:
		author = str(submitted_by.get("display_name", author))

	var issue = {
		"key": "modio:" + item_id,
		"source": "modio",
		"source_label": "mod.io",
		"id": item_id,
		"title": title,
		"author": author,
		"status": "",
		"busy": false,
		"resolved": false,
		"meta": {
			"name": title,
			"profile_url": str(mod.get("profile_url", "")),
		},
	}

	if pending.has(item_id):
		issue["state"] = "pending"
		issue["status"] = "Downloaded. Restart the game to install it."
		issue["resolved"] = true
		return issue

	var installed = ModIO.get_installed(item_id)
	if installed.empty():
		issue["state"] = "missing"
		issue["status"] = "Not downloaded"
		return issue

	var installed_path = str(installed.get("path", ""))
	if installed_path == "" or not File.new().file_exists(installed_path):
		issue["state"] = "missing"
		issue["status"] = "The installed file is missing"
		return issue

	var modfile = mod.get("modfile", {})
	var latest_file_id := 0
	if typeof(modfile) == TYPE_DICTIONARY:
		latest_file_id = int(modfile.get("id", 0))
	if latest_file_id > 0 and latest_file_id != int(installed.get("file_id", 0)):
		issue["state"] = "update"
		issue["status"] = "An update is available"
		return issue
	return {}


func _on_steam_install_started(item_id, _title) -> void:
	_set_status("steam:" + str(item_id), "Downloading in the background...")


func _on_steam_install_progress(item_id, downloaded, total) -> void:
	var text = "Downloading in the background..."
	if int(total) > 0:
		text = "%s / %s" % [_format_bytes(int(downloaded)), _format_bytes(int(total))]
	_set_status("steam:" + str(item_id), text)


func _on_steam_install_finished(item_id, _entry) -> void:
	var key = "steam:" + str(item_id)
	var issue = issues.get(key, {})
	if issue.empty():
		return
	issue["busy"] = false
	issue["resolved"] = true
	_set_status(key, "Downloaded. Restart the game to load it.")


func _on_steam_install_failed(item_id, message) -> void:
	_finish_issue("steam:" + str(item_id), str(message))


func _on_steam_removed(item_id) -> void:
	_remove_issue("steam:" + str(item_id))


func _on_modio_files(parsed, code, binds) -> void:
	var key = binds[0]
	var issue = issues.get(key, {})
	if issue.empty():
		return
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		_finish_issue(key, "Couldn't get the mod.io file list (HTTP %s)." % str(code))
		return
	var files = parsed.get("data", [])
	if typeof(files) != TYPE_ARRAY or files.empty():
		_finish_issue(key, "This mod.io mod has no downloadable file.")
		return
	files.sort_custom(self, "_sort_files_newest")
	var file = files[0]
	var binary_url = ""
	if typeof(file.get("download")) == TYPE_DICTIONARY:
		binary_url = str(file.download.get("binary_url", ""))
	if binary_url == "":
		ModIO.request_modfile_download_url(int(issue.id), int(file.get("id", 0)),
			self, "_on_modio_download_url", [key, file])
		return
	_download_modio_file(key, file, binary_url)


func _on_modio_download_url(parsed, code, binds) -> void:
	var key = binds[0]
	var file = binds[1]
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY \
	or typeof(parsed.get("download")) != TYPE_DICTIONARY:
		_finish_issue(key, "Couldn't get the mod.io download link (HTTP %s)." % str(code))
		return
	_download_modio_file(key, file, str(parsed.download.get("binary_url", "")))


func _download_modio_file(key: String, file: Dictionary, binary_url: String) -> void:
	var issue = issues.get(key, {})
	if issue.empty() or binary_url == "":
		_finish_issue(key, "Couldn't get the mod.io download link.")
		return
	var destination = WORKSHOP_STORE.modio_download_path(issue.id, file)
	_set_status(key, "Downloading in the background...")
	ModIO.download(binary_url, destination, self, "_on_modio_download_finished",
		[key, file, issue.id], int(file.get("filesize", 0)))


func _on_modio_download_finished(ok, payload, binds) -> void:
	var key = binds[0]
	var file = binds[1]
	if not ok:
		_finish_issue(key, "Download failed: " + str(payload))
		return
	var issue = issues.get(key, {})
	if issue.empty():
		WORKSHOP_STORE.modio_discard(binds[2])
		return
	issue.meta["user_id"] = int(ModIOAuth.user_id)
	WORKSHOP_STORE.modio_record_pending(issue.id, issue.meta, str(payload), file)
	issue["busy"] = false
	issue["resolved"] = true
	_set_status(key, "Downloaded. Queued for the next launch.")


func _modio_cancel_issue(key: String, item_id: int) -> void:
	_set_status(key, "Unsubscribing...")
	ModIO.set_subscription(item_id, false, self, "_on_modio_unsubscribed", [key, item_id])


func _on_modio_unsubscribed(_parsed, code, binds) -> void:
	var key = binds[0]
	var item_id = binds[1]
	if code != 200 and code != 201 and code != 204:
		_finish_issue(key, "Couldn't unsubscribe (HTTP %s)." % str(code))
		return
	ModIO.queue_uninstall(item_id)
	WORKSHOP_STORE.modio_discard(item_id)
	_remove_issue(key)


func _sort_files_newest(a, b) -> bool:
	return int(a.get("date_added", 0)) > int(b.get("date_added", 0))


func _set_status(key: String, text: String) -> void:
	var issue = issues.get(key, {})
	if issue.empty():
		return
	issue["status"] = text
	_emit()


func _finish_issue(key: String, text: String) -> void:
	var issue = issues.get(key, {})
	if issue.empty():
		return
	issue["busy"] = false
	issue["status"] = text
	_emit()


func _remove_issue(key: String) -> void:
	issues.erase(key)
	_emit()


func _emit() -> void:
	emit_signal("issues_changed", _visible_issues())


func _visible_issues() -> Dictionary:
	var visible := {}
	for key in issues:
		if not _dismissed.has(key):
			visible[key] = issues[key]
	return visible


func _format_bytes(value: int) -> String:
	if value <= 0:
		return "0 B"
	if value < 1024:
		return str(value) + " B"
	if value < 1048576:
		return "%.1f KB" % (value / 1024.0)
	return "%.1f MB" % (value / 1048576.0)
