extends Control

const MODIFIER_KEYS = [KEY_CONTROL, KEY_SHIFT, KEY_ALT, KEY_META]

var rebinding_action = ""
var rebind_buttons = {}
var confirm_dialog: ConfirmationDialog
# A bare modifier press is deferred until its release: hold it and tap a real
# key for a combo (Ctrl+Z), or press-and-release it alone to bind the modifier
# on its own (e.g. Shift for XY-plot snap).
var pending_modifier = 0

func _ready():
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "reset all hotkeys to defaults?"
	confirm_dialog.window_title = "reset hotkeys"
	confirm_dialog.connect("confirmed", Hotkeys, "reset_to_defaults")
	add_child(confirm_dialog)
	build_list()
	Hotkeys.connect("binding_changed", self, "_on_binding_changed")
	if not Global.is_connected("mobile_ui_changed", self, "_on_mobile_ui_changed"):
		Global.connect("mobile_ui_changed", self, "_on_mobile_ui_changed")


func _on_mobile_ui_changed(_mobile):
	build_list()

func build_list():
	var list = $"%HotkeysList"
	for child in list.get_children():
		child.queue_free()
	rebind_buttons.clear()
	for entry in Hotkeys.REBINDABLE:
		if not Hotkeys.is_action_enabled(entry.action):
			continue
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label = Label.new()
		label.text = entry.label
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var btn = Button.new()
		btn.rect_min_size = Vector2(80, 26) if Global.mobile_ui else Vector2(80, 0)
		btn.text = _button_text_for(entry.action)
		btn.connect("pressed", self, "_start_rebind", [entry.action])
		row.add_child(btn)
		rebind_buttons[entry.action] = btn
		list.add_child(row)
	var reset_btn = Button.new()
	reset_btn.text = "reset to defaults"
	reset_btn.connect("pressed", confirm_dialog, "popup_centered")
	list.add_child(reset_btn)
	UIManager.register_menu(self, list.get_children())

func _button_text_for(action: String) -> String:
	if rebinding_action == action:
		return "press a key..."
	var key_name = Hotkeys.get_display_name(action)
	return key_name if key_name != "" else "(unbound)"

func _start_rebind(action: String):
	pending_modifier = 0
	var previous = rebinding_action
	rebinding_action = "" if previous == action else action
	if previous != "":
		_refresh_button(previous)
	if rebinding_action != "":
		_refresh_button(rebinding_action)

func _refresh_button(action: String):
	if action in rebind_buttons:
		rebind_buttons[action].text = _button_text_for(action)

func _input(event):
	if rebinding_action == "":
		return
	if not (event is InputEventKey) or event.echo:
		return
	var base = event.scancode if event.scancode != 0 else event.physical_scancode
	var is_modifier = base in MODIFIER_KEYS
	if event.pressed:
		if is_modifier:
			# Defer the decision to release: a held modifier may still become
			# the prefix of a combo if a real key is tapped next.
			pending_modifier = base
			return
		# Real key — commit now, folding in any modifiers held alongside it
		# (Ctrl+Z -> KEY_Z | KEY_MASK_CTRL).
		var code = base
		if event.control:
			code |= KEY_MASK_CTRL
		if event.shift:
			code |= KEY_MASK_SHIFT
		if event.alt:
			code |= KEY_MASK_ALT
		if event.meta:
			code |= KEY_MASK_META
		_finish_rebind(base, code)
	elif is_modifier and base == pending_modifier:
		# Pressed and released with no real key in between -> bind the bare
		# modifier (scancode only, no modifier mask).
		_finish_rebind(base, base)

func _finish_rebind(base: int, code: int):
	get_tree().set_input_as_handled()
	var action = rebinding_action
	rebinding_action = ""
	pending_modifier = 0
	if base == KEY_ESCAPE:
		Hotkeys.clear_binding(action)
	else:
		var ok = Hotkeys.rebind(action, code)
		if not ok:
			# protected key - just refresh, leave binding as-is
			_refresh_button(action)

func _on_binding_changed(action):
	_refresh_button(action)
