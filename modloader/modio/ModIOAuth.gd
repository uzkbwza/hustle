extends Node

const AUTH_CONFIG := "user://modio_auth.cfg"
const DEFAULT_TOKEN_LIFETIME := 31536000

var access_token: String = ""
var refresh_token: String = ""
var expires_at: int = 0
var username: String = ""
var user_id: int = 0

var _device_key: PoolByteArray = PoolByteArray()
var _pending: String = ""
var _generation := 0

signal login_success
signal login_failed(message)
signal logout_done
signal user_updated
signal email_code_sent
signal auth_status(message)


func _ready() -> void:
	_load_tokens()
	if is_logged_in():
		_refresh_user()


func is_logged_in() -> bool:
	return access_token != "" and OS.get_unix_time() < expires_at


func is_busy() -> bool:
	return _pending != ""


func get_access_token() -> String:
	if access_token == "":
		return ""
	if OS.get_unix_time() >= expires_at:
		if refresh_token != "" and _pending == "":
			_refresh_access_token()
		return ""
	return access_token


func request_email_code(email: String) -> void:
	if _pending != "":
		emit_signal("login_failed", "Another sign-in is already in progress")
		return
	email = email.strip_edges()
	if email == "" or not "@" in email:
		emit_signal("login_failed", "Enter a valid email address")
		return
	_pending = "email"
	emit_signal("auth_status", "Sending a security code to " + email + "...")
	_post_form("/oauth/emailrequest", {"email": email}, "_on_email_request_done")


func submit_email_code(code_input: String) -> void:
	if _pending != "":
		emit_signal("login_failed", "Another sign-in is already in progress")
		return
	code_input = code_input.strip_edges()
	if code_input == "":
		emit_signal("login_failed", "Enter the security code from your email")
		return
	_pending = "email"
	emit_signal("auth_status", "Verifying security code...")
	_post_form("/oauth/emailexchange", {"security_code": code_input}, "_on_email_exchange_done")


func logout() -> void:
	_generation += 1
	_pending = ""
	access_token = ""
	refresh_token = ""
	expires_at = 0
	username = ""
	user_id = 0
	_clear_config()
	emit_signal("logout_done")


func _on_email_request_done(data, code) -> void:
	_pending = ""
	if code != 200 or typeof(data) != TYPE_DICTIONARY:
		emit_signal("login_failed", _describe_error(data, code))
		return
	emit_signal("auth_status", "Check your inbox for the mod.io security code.")
	emit_signal("email_code_sent")


func _on_email_exchange_done(data, code) -> void:
	_pending = ""
	if code != 200 or typeof(data) != TYPE_DICTIONARY or not data.has("access_token"):
		emit_signal("login_failed", _describe_error(data, code))
		return
	_apply_token(data)


func _load_tokens() -> void:
	if not File.new().file_exists(AUTH_CONFIG):
		return
	var f = File.new()
	if f.open_encrypted(AUTH_CONFIG, File.READ, _get_device_key()) != OK:
		_clear_config()
		return
	var text = f.get_as_text()
	f.close()
	if text == "":
		return
	var parsed = JSON.parse(text)
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return
	var data = parsed.result
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	expires_at = int(data.get("expires_at", 0))
	user_id = int(data.get("user_id", 0))
	if access_token != "" and OS.get_unix_time() >= expires_at and refresh_token != "":
		_refresh_access_token()
	elif access_token != "" and OS.get_unix_time() >= expires_at:
		access_token = ""
		refresh_token = ""
		expires_at = 0
		user_id = 0
		_clear_config()


func _save_tokens() -> void:
	var data = {
		"access_token": access_token,
		"refresh_token": refresh_token,
		"expires_at": expires_at,
		"user_id": user_id,
	}
	var f = File.new()
	if f.open_encrypted(AUTH_CONFIG, File.WRITE, _get_device_key()) != OK:
		push_warning("ModIOAuth: could not open %s for writing" % AUTH_CONFIG)
		return
	f.store_string(JSON.print(data, "  ", true))
	f.close()


func _clear_config() -> void:
	var dir = Directory.new()
	if dir.file_exists(ProjectSettings.globalize_path(AUTH_CONFIG)):
		dir.remove(ProjectSettings.globalize_path(AUTH_CONFIG))


func _get_device_key() -> PoolByteArray:
	if _device_key.size() == 32:
		return _device_key
	var project = "HUSTLE"
	if ProjectSettings.has_setting("application/config/name"):
		project = str(ProjectSettings.get_setting("application/config/name"))
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((OS.get_unique_id() + "|" + project + "|modio_auth").to_utf8())
	_device_key = ctx.finish()
	return _device_key


func _api_url() -> String:
	return ModIO.get_write_base_url()


func refresh_user() -> void:
	_refresh_user()


func _refresh_user() -> void:
	if not is_logged_in():
		return
	var req = HTTPRequest.new()
	add_child(req)
	req.use_threads = true
	req.timeout = 20.0
	req.connect("request_completed", self, "_on_user_response", [req])
	var headers = PoolStringArray([
		"Authorization: Bearer " + access_token,
		"Accept: application/json",
		"Origin: https://mod.io",
	])
	if req.request(_api_url() + "/me?api_key=" + ModIO.api_key.http_escape(), headers) != OK:
		req.queue_free()


func _on_user_response(result, code, _headers, body, req) -> void:
	req.queue_free()
	if code == 401:
		if access_token != "" and body.get_string_from_utf8().find("access token") != -1:
			logout()
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("mod.io account check failed: ", code)
		return
	if body.size() > ModIO.MAX_JSON_BYTES:
		return
	var parsed = JSON.parse(body.get_string_from_utf8())
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return
	var data = parsed.result.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return
	username = str(data.get("username", ""))
	var new_id = int(data.get("id", 0))
	if new_id != user_id:
		user_id = new_id
		_save_tokens()
	emit_signal("user_updated")


func _post_form(path: String, fields: Dictionary, callback: String, generation: int = -1) -> void:
	if generation < 0:
		generation = _generation
	var req = HTTPRequest.new()
	add_child(req)
	req.use_threads = true
	req.timeout = 30.0
	req.connect("request_completed", self, "_on_form_response", [req, callback, generation])
	var headers = PoolStringArray([
		"Content-Type: application/x-www-form-urlencoded",
		"Accept: application/json",
		"Origin: https://mod.io",
	])
	var url = _api_url() + path + "?api_key=" + ModIO.api_key.http_escape()
	if req.request(url, headers, true, HTTPClient.METHOD_POST, _form_encode(fields)) != OK:
		req.queue_free()
		_pending = ""
		emit_signal("login_failed", "Request failed. Check your connection and try again.")


func _on_form_response(result, code, _headers, body, req, callback, generation) -> void:
	req.queue_free()
	if generation != _generation:
		return
	var parsed = null
	if result == HTTPRequest.RESULT_SUCCESS and body.size() <= ModIO.MAX_JSON_BYTES:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.error == OK and typeof(json.result) == TYPE_DICTIONARY:
			parsed = json.result
	if result != HTTPRequest.RESULT_SUCCESS:
		parsed = null
		code = 0
	call(callback, parsed, code)


func _refresh_access_token() -> void:
	if refresh_token == "":
		access_token = ""
		expires_at = 0
		_clear_config()
		return
	_pending = "refresh"
	_post_form("/oauth/token", {
		"grant_type": "refresh_token",
		"refresh_token": refresh_token,
	}, "_on_refresh_done")


func _on_refresh_done(data, code) -> void:
	_pending = ""
	if code != 200 or typeof(data) != TYPE_DICTIONARY or not data.has("access_token"):
		access_token = ""
		refresh_token = ""
		expires_at = 0
		username = ""
		user_id = 0
		_clear_config()
		emit_signal("logout_done")
		return
	_apply_token(data)


func _apply_token(data: Dictionary) -> void:
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	expires_at = int(data.get("date_expires", 0))
	if expires_at <= OS.get_unix_time():
		expires_at = OS.get_unix_time() + int(data.get("expires_in", DEFAULT_TOKEN_LIFETIME)) - 60
	if access_token == "":
		_pending = ""
		emit_signal("login_failed", "No access token in the response")
		return
	_save_tokens()
	_pending = ""
	print("mod.io sign-in token received")
	emit_signal("login_success")
	_refresh_user()


func _form_encode(fields: Dictionary) -> String:
	var out := ""
	for key in fields:
		if out != "":
			out += "&"
		out += str(key).http_escape() + "=" + str(fields[key]).http_escape()
	return out


func _describe_error(data, code: int) -> String:
	if code == 0:
		return "mod.io: could not reach the server. Check your connection."
	var desc = ""
	if typeof(data) == TYPE_DICTIONARY:
		desc = str(data.get("error_description", ""))
		var error = data.get("error", null)
		if desc == "" and typeof(error) == TYPE_DICTIONARY:
			desc = str(error.get("message", error.get("error_description", "")))
		elif desc == "" and typeof(error) == TYPE_STRING:
			desc = error
		if desc == "":
			desc = str(data.get("message", ""))
	if desc == "":
		desc = "HTTP %d" % code
	return "mod.io: " + desc
