extends Node
class_name ModIOUploadAPI

signal mod_created(mod_id, mod_data)
signal mod_create_failed(error)
signal guide_created(guide_id, guide_data)
signal guide_create_failed(error)
signal collection_created(collection_id, collection_data)
signal collection_create_failed(error)
signal file_upload_started(total_bytes)
signal file_upload_done(modfile_id, modfile_data)
signal file_upload_failed(error)

const MULTIPART_NL := "\r\n"
const MAX_RESPONSE_BYTES := 1024 * 1024

var _active_upload: HTTPRequest = null
var _boundary_counter := 0


func create_mod(mod_name: String, summary: String, description: String,
		logo_path: String = "", tags: Array = [], visibility: int = 1) -> void:

	if not _require_login("mod_create_failed"):
		return
	if ModIO.game_id <= 0:
		emit_signal("mod_create_failed", "mod.io game_id is not configured")
		return
	if logo_path == "" or not File.new().file_exists(logo_path):
		emit_signal("mod_create_failed", "A logo image is required")
		return

	var multipart = new_multipart(_new_boundary())
	multipart_field(multipart, "name", mod_name)
	multipart_field(multipart, "summary", summary)
	multipart_field(multipart, "description", description)
	multipart_field(multipart, "visible", str(visibility))
	for tag in tags:
		multipart_field(multipart, "tags[]", str(tag))
	if logo_path != "" and not multipart_file(multipart, "logo", logo_path, _image_content_type(logo_path)):
		emit_signal("mod_create_failed", "Could not read logo: " + logo_path)
		return

	_post("/games/%d/mods" % ModIO.game_id, multipart_finish(multipart), multipart.boundary, "mod")


func create_guide(guide_name: String, summary: String, description: String,
		logo_path: String = "", tags: Array = []) -> void:

	if not _require_login("guide_create_failed"):
		return
	if ModIO.game_id <= 0:
		emit_signal("guide_create_failed", "mod.io game_id is not configured")
		return
	if logo_path == "" or not File.new().file_exists(logo_path):
		emit_signal("guide_create_failed", "A logo image is required")
		return

	var multipart = new_multipart(_new_boundary())
	multipart_field(multipart, "name", guide_name)
	multipart_field(multipart, "summary", summary)
	multipart_field(multipart, "description", description)
	for tag in tags:
		multipart_field(multipart, "tags[]", str(tag))
	if not multipart_file(multipart, "logo", logo_path, _image_content_type(logo_path)):
		emit_signal("guide_create_failed", "Could not read logo: " + logo_path)
		return

	_post("/games/%d/guides" % ModIO.game_id, multipart_finish(multipart), multipart.boundary, "guide")


func create_collection(collection_name: String, summary: String, description: String,
		logo_path: String = "", mod_ids: Array = [], visible: bool = false) -> void:

	if not _require_login("collection_create_failed"):
		return
	if ModIO.game_id <= 0:
		emit_signal("collection_create_failed", "mod.io game_id is not configured")
		return
	if logo_path == "" or not File.new().file_exists(logo_path):
		emit_signal("collection_create_failed", "A logo image is required")
		return

	var multipart = new_multipart(_new_boundary())
	multipart_field(multipart, "name", collection_name)
	multipart_field(multipart, "summary", summary)
	multipart_field(multipart, "description", description)
	multipart_field(multipart, "visible", "1" if visible else "0")
	multipart_field(multipart, "collection_tags", "")
	for mod_id in mod_ids:
		multipart_field(multipart, "mod_ids[]", str(mod_id))
	if not multipart_file(multipart, "logo", logo_path, _image_content_type(logo_path)):
		emit_signal("collection_create_failed", "Could not read logo: " + logo_path)
		return

	_post("/games/%d/collections" % ModIO.game_id, multipart_finish(multipart), multipart.boundary, "collection")


func upload_file(mod_id: int, zip_path: String, version: String = "1.0",
		changelog: String = "", active: bool = true) -> void:

	if not _require_login("file_upload_failed"):
		return
	if ModIO.game_id <= 0:
		emit_signal("file_upload_failed", "mod.io game_id is not configured")
		return
	if not File.new().file_exists(zip_path):
		emit_signal("file_upload_failed", "Zip not found: " + zip_path)
		return
	if zip_path.get_extension().to_lower() != "zip":
		emit_signal("file_upload_failed", "Only .zip files can be uploaded")
		return

	var multipart = new_multipart(_new_boundary())
	multipart_field(multipart, "version", version)
	multipart_field(multipart, "changelog", changelog)
	multipart_field(multipart, "active", "true" if active else "false")
	if not multipart_file(multipart, "filedata", zip_path, "application/zip"):
		emit_signal("file_upload_failed", "Could not read: " + zip_path)
		return

	var body = multipart_finish(multipart)
	emit_signal("file_upload_started", body.size())
	_post("/games/%d/mods/%d/files" % [ModIO.game_id, mod_id], body, multipart.boundary, "file")


func cancel_upload() -> void:
	if _active_upload != null and is_instance_valid(_active_upload):
		_active_upload.queue_free()
	_active_upload = null


func _require_login(fail_signal: String) -> bool:
	if not ModIOAuth.is_logged_in():
		emit_signal(fail_signal, "Not logged in to mod.io")
		return false
	return true


func _post(path: String, body: PoolByteArray, boundary: String, kind: String) -> void:
	var url = ModIO.get_write_base_url() + path
	if not ModIO.is_allowed_url(url):
		_fail(kind, "Blocked an untrusted request URL")
		return
	var req = HTTPRequest.new()
	add_child(req)
	req.use_threads = true
	req.timeout = 0.0
	req.connect("request_completed", self, "_on_request_completed", [req, kind])

	var headers = PoolStringArray([
		"Authorization: Bearer " + ModIOAuth.get_access_token(),
		"Content-Type: multipart/form-data; boundary=" + boundary,
		"Accept: application/json",
		"Origin: https://mod.io",
	])

	var err = req.request_raw(url, headers, true,
		HTTPClient.METHOD_POST, body)
	if err != OK:
		req.queue_free()
		_fail(kind, "Request failed: %d" % err)
		return
	_active_upload = req


func _on_request_completed(result, code, _headers, body, req, kind) -> void:
	if _active_upload == req:
		_active_upload = null
	req.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		_fail(kind, "Network error: %d" % result)
		return
	if body.size() > MAX_RESPONSE_BYTES:
		_fail(kind, "Response from mod.io was too large")
		return

	var parsed = JSON.parse(body.get_string_from_utf8())
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		_fail(kind, "Invalid JSON response from mod.io")
		return

	var data = parsed.result
	if code != 200 and code != 201:
		_fail(kind, _describe_error(data, code))
		return

	if kind == "mod":
		var mod_id = int(data.get("id", 0))
		if mod_id == 0:
			_fail(kind, "No mod ID in response")
			return
		emit_signal("mod_created", mod_id, data)
	elif kind == "guide":
		var guide_id = int(data.get("id", 0))
		if guide_id == 0:
			_fail(kind, "No guide ID in response")
			return
		emit_signal("guide_created", guide_id, data)
	elif kind == "collection":
		var collection_id = int(data.get("id", 0))
		if collection_id == 0:
			_fail(kind, "No collection ID in response")
			return
		emit_signal("collection_created", collection_id, data)
	else:
		emit_signal("file_upload_done", int(data.get("id", 0)), data)


func _fail(kind: String, message: String) -> void:
	if kind == "mod":
		emit_signal("mod_create_failed", message)
	elif kind == "guide":
		emit_signal("guide_create_failed", message)
	elif kind == "collection":
		emit_signal("collection_create_failed", message)
	else:
		emit_signal("file_upload_failed", message)


func _new_boundary() -> String:
	_boundary_counter += 1
	return "----ModIOBoundary" + str(OS.get_ticks_msec()) + "_" + str(_boundary_counter)


static func new_multipart(boundary: String) -> Dictionary:
	return {"boundary": boundary, "parts": []}


static func multipart_field(multipart: Dictionary, field_name: String, value: String) -> void:
	_multipart_begin(multipart, 'form-data; name="%s"' % field_name, "")
	multipart.parts.append(value.to_utf8())
	multipart.parts.append(MULTIPART_NL.to_utf8())


static func multipart_file(multipart: Dictionary, field_name: String, path: String,
		content_type: String) -> bool:

	var f = File.new()
	if f.open(path, File.READ) != OK:
		return false
	var content = f.get_buffer(f.get_len())
	f.close()
	var safe_name = path.get_file().replace("\"", "_").replace("\r", "").replace("\n", "")
	_multipart_begin(multipart, 'form-data; name="%s"; filename="%s"' % [field_name, safe_name],
		content_type)
	multipart.parts.append(content)
	multipart.parts.append(MULTIPART_NL.to_utf8())
	return true


static func multipart_finish(multipart: Dictionary) -> PoolByteArray:
	multipart.parts.append(("--" + multipart.boundary + "--" + MULTIPART_NL).to_utf8())
	var body := PoolByteArray()
	for part in multipart.parts:
		body.append_array(part)
	return body


static func _multipart_begin(multipart: Dictionary, disposition: String, content_type: String) -> void:
	multipart.parts.append(("--" + multipart.boundary + MULTIPART_NL).to_utf8())
	multipart.parts.append(("Content-Disposition: " + disposition + MULTIPART_NL).to_utf8())
	if content_type != "":
		multipart.parts.append(("Content-Type: " + content_type + MULTIPART_NL).to_utf8())
	multipart.parts.append(MULTIPART_NL.to_utf8())


func _image_content_type(path: String) -> String:
	var ext = path.get_extension().to_lower()
	if ext == "png":
		return "image/png"
	if ext == "webp":
		return "image/webp"
	return "image/jpeg"


func _describe_error(data: Dictionary, code: int) -> String:
	if data.has("errors"):
		var errs = data["errors"]
		if typeof(errs) == TYPE_DICTIONARY:
			var parts := PoolStringArray()
			for key in errs:
				var value = errs[key]
				if typeof(value) == TYPE_ARRAY and value.size() > 0:
					parts.append(str(key) + ": " + str(value[0]))
				else:
					parts.append(str(key) + ": " + str(value))
			if parts.size() > 0:
				return "mod.io: " + parts.join(" | ")

	var desc = str(data.get("error", ""))
	if typeof(data.get("error")) == TYPE_DICTIONARY:
		desc = str(data.error.get("message", data.error.get("error_description", "")))
	if desc == "":
		desc = str(data.get("error_description", ""))
	if desc == "":
		desc = "HTTP %d" % code
	return "mod.io: " + desc
