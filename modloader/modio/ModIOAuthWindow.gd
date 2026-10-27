extends Window

const TERMS_URL := "https://mod.io/terms"
const PRIVACY_URL := "https://mod.io/privacy"
const SIGNED_IN_HEIGHT := 88
const SIGNED_OUT_HEIGHT := 150
const DESKTOP_WIDTH := 520.0
const MOBILE_SCREEN_MARGIN := 8.0

onready var account_row: HBoxContainer = $VBoxContainer/Contents/Main/AccountRow
onready var title_label: Label = $VBoxContainer/TitleBar/Title
onready var account_label: Label = $VBoxContainer/Contents/Main/AccountRow/AccountLabel
onready var signout_btn: Button = $VBoxContainer/Contents/Main/AccountRow/SignOut
onready var email_panel: VBoxContainer = $VBoxContainer/Contents/Main/EmailPanel
onready var email_step1: HBoxContainer = $VBoxContainer/Contents/Main/EmailPanel/EmailStep1
onready var email_step2: VBoxContainer = $VBoxContainer/Contents/Main/EmailPanel/EmailStep2
onready var email_edit: LineEdit = $VBoxContainer/Contents/Main/EmailPanel/EmailStep1/EmailEdit
onready var email_send_btn: Button = $VBoxContainer/Contents/Main/EmailPanel/EmailStep1/EmailSend
onready var code_edit: LineEdit = $VBoxContainer/Contents/Main/EmailPanel/EmailStep2/EmailCodeRow/CodeEdit
onready var code_verify_btn: Button = $VBoxContainer/Contents/Main/EmailPanel/EmailStep2/EmailCodeRow/CodeVerify
onready var email_back_btn: Button = $VBoxContainer/Contents/Main/EmailPanel/EmailStep2/EmailBack
onready var status_label: Label = $VBoxContainer/Contents/Main/Status
onready var terms_label: Label = $VBoxContainer/Contents/Main/Terms
onready var links_row: HBoxContainer = $VBoxContainer/Contents/Main/Links
onready var terms_btn: Button = $VBoxContainer/Contents/Main/Links/TermsBtn
onready var privacy_btn: Button = $VBoxContainer/Contents/Main/Links/PrivacyBtn


func _ready() -> void:
	$"%Close".connect("pressed", self, "_on_close")
	signout_btn.connect("pressed", self, "_on_signout_pressed")
	email_send_btn.connect("pressed", self, "_on_email_send_pressed")
	email_edit.connect("text_entered", self, "_on_email_send_pressed")
	code_verify_btn.connect("pressed", self, "_on_code_verify_pressed")
	code_edit.connect("text_entered", self, "_on_code_verify_pressed")
	email_back_btn.connect("pressed", self, "_on_email_back_pressed")
	terms_btn.connect("pressed", self, "_on_terms_pressed")
	privacy_btn.connect("pressed", self, "_on_privacy_pressed")

	UIManager.register_menu(self, [
		$VBoxContainer/TitleBar/Close, signout_btn, email_edit, email_send_btn,
		code_edit, code_verify_btn, email_back_btn, terms_btn, privacy_btn,
	])

	_connect_auth()
	refresh()
	Global.connect("mobile_ui_changed", self, "adjust_ui")


func _connect_auth() -> void:
	ModIOAuth.connect("login_success", self, "_on_login_success")
	ModIOAuth.connect("login_failed", self, "_on_login_failed")
	ModIOAuth.connect("auth_status", self, "_on_auth_status")
	ModIOAuth.connect("email_code_sent", self, "_on_email_code_sent")
	ModIOAuth.connect("logout_done", self, "_on_logout_done")
	ModIOAuth.connect("user_updated", self, "_on_user_updated")


func open() -> void:
	show()
	raise()
	refresh()
	if not _is_signed_in() and not ModIOAuth.is_busy():
		_reset_steps()


func refresh() -> void:
	var signed_in = _is_signed_in()
	title_label.text = "mod.io Account" if signed_in else "Sign in to mod.io"
	account_row.visible = signed_in
	email_panel.visible = not signed_in
	terms_label.visible = not signed_in
	links_row.visible = not signed_in
	status_label.visible = not signed_in
	_apply_window_size(signed_in)
	if signed_in:
		var who = str(ModIOAuth.username)
		account_label.text = "Signed in to mod.io" + (" as " + who if who != "" else "")
	else:
		account_label.text = ""
	_set_status("")


func adjust_ui(_is_mobile: bool) -> void:
	_apply_window_size(_is_signed_in())


func _apply_window_size(signed_in: bool) -> void:
	var height = SIGNED_IN_HEIGHT if signed_in else SIGNED_OUT_HEIGHT
	var width = DESKTOP_WIDTH
	if Global.mobile_ui:
		width = min(DESKTOP_WIDTH, max(1.0, get_viewport_rect().size.x - MOBILE_SCREEN_MARGIN * 2.0))
	margin_left = -width * 0.5
	margin_right = width * 0.5
	margin_top = -height * 0.5
	margin_bottom = height * 0.5


func _is_signed_in() -> bool:
	return ModIOAuth.is_logged_in()


func _reset_steps() -> void:
	email_step1.visible = true
	email_step2.visible = false
	email_edit.text = ""
	code_edit.text = ""


func _set_status(text: String) -> void:
	status_label.text = text


func _on_email_send_pressed(_text = "") -> void:
	ModIOAuth.request_email_code(email_edit.text)


func _on_code_verify_pressed(_text = "") -> void:
	ModIOAuth.submit_email_code(code_edit.text)


func _on_email_back_pressed() -> void:
	email_step1.visible = true
	email_step2.visible = false
	code_edit.text = ""
	_set_status("")


func _on_signout_pressed() -> void:
	ModIOAuth.logout()


func _on_login_success() -> void:
	refresh()


func _on_login_failed(message: String) -> void:
	_set_status(str(message))


func _on_auth_status(message: String) -> void:
	_set_status(str(message))


func _on_email_code_sent() -> void:
	email_step1.visible = false
	email_step2.visible = true
	code_edit.grab_focus()


func _on_logout_done() -> void:
	refresh()
	_reset_steps()
	_set_status("Signed out of mod.io.")


func _on_user_updated() -> void:
	if _is_signed_in():
		var who = str(ModIOAuth.username)
		account_label.text = "Signed in to mod.io" + (" as " + who if who != "" else "")


func _on_terms_pressed() -> void:
	ModIO.open_web_url(TERMS_URL)


func _on_privacy_pressed() -> void:
	ModIO.open_web_url(PRIVACY_URL)


func _on_close() -> void:
	hide()
