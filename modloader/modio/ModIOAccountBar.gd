extends VBoxContainer
class_name ModIOAccountBar

signal signed_in
signal signed_out

onready var _toggle_btn: Button = $"%Toggle"

var _auth_window = null
var _compact := false


func _ready() -> void:
	_toggle_btn.connect("pressed", self, "_on_toggle_pressed")
	ModIOAuth.connect("login_success", self, "_on_login_success")
	ModIOAuth.connect("logout_done", self, "_on_logout_done")
	ModIOAuth.connect("user_updated", self, "refresh")
	ModIOAuth.connect("auth_status", self, "_on_auth_status")
	ModIOAuth.connect("login_failed", self, "_on_auth_status")
	refresh()
	UIManager.register_control(self, ui_elements())


func set_compact(compact: bool) -> void:
	if _compact == compact:
		return
	_compact = compact
	refresh()


func refresh() -> void:
	if ModIOAuth.is_logged_in():
		_toggle_btn.text = "Sign out"
	elif ModIOAuth.is_busy():
		_toggle_btn.text = "Signing in..." if _compact else "Sign in"
	else:
		_toggle_btn.text = "Sign in"


func is_signed_in() -> bool:
	return ModIOAuth.is_logged_in()


func ui_elements() -> Array:
	return [_toggle_btn]


func open_auth_window() -> void:
	call_deferred("_open_auth_window")


func _open_auth_window() -> void:
	if _auth_window == null or not is_instance_valid(_auth_window):
		_auth_window = preload("res://modloader/modio/ModIOAuthWindow.tscn").instance()
		get_tree().current_scene.get_node("%ModIOAuthLayer").add_child(_auth_window)
	_auth_window.open()


func _on_toggle_pressed() -> void:
	if is_signed_in():
		ModIOAuth.logout()
		return
	open_auth_window()


func _on_login_success() -> void:
	refresh()
	emit_signal("signed_in")


func _on_auth_status(_message: String) -> void:
	refresh()


func _on_logout_done() -> void:
	refresh()
	emit_signal("signed_out")
