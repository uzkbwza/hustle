extends Node

signal binding_changed(action)

const LOCK_IN = "submit_action"
const WATCH_REPLAY = "playback"
const FRAME_ADVANCE = "frame_advance"
const TOGGLE_FRAME_ADVANCE = "toggle_frame_advance"
const EDIT_REPLAY = "edit_replay"
const PAUSE = "pause"
const FOCUS_NEXT = "ui_focus_next"
const ACCEPT = "ui_accept"
const OPEN_DEBUG_PANEL = "open_debug_panel"

const TOGGLE_HUD = "toggle_hud"
const OPEN_CHAT = "open_chat"
const SEND_CHAT = "send_chat"
const TOGGLE_PREDICTIONS_MENU = "toggle_predictions_menu"
const TOGGLE_NUDGE_MENU = "toggle_nudge_menu"

const TOGGLE_FREE_CANCEL = "toggle_free_cancel"
const TOGGLE_PREDICTION = "toggle_prediction"
const TOGGLE_HITBOXES = "toggle_hitboxes"
const CLEAR_PARTICLES = "clear_particles"
const TOGGLE_PLAYBACK_CONTROLS = "toggle_playback_controls"
const TOGGLE_PROJECTILE_OWNERS = "toggle_projectile_owners"
const RESET_ZOOM = "reset_zoom"
const PREDICTION_SPEED_1 = "prediction_speed_1"
const PREDICTION_SPEED_2 = "prediction_speed_2"
const PREDICTION_SPEED_3 = "prediction_speed_3"
# 0.5x slot — named by speed (not "_4" / "_5") because it was inserted between
# 0.25x and 1x after _1/_2/_3 had shipped, and renaming the existing constants
# would silently break any saved keybindings users have for them.
const PREDICTION_SPEED_HALF = "prediction_speed_half"
const NUDGE_LEFT = "nudge_left"
const NUDGE_RIGHT = "nudge_right"
const NUDGE_UP = "nudge_up"
const NUDGE_DOWN = "nudge_down"
const TOGGLE_FULLSCREEN = "toggle_fullscreen"
const PLAYBACK_SPEED_1 = "playback_speed_1"
const PLAYBACK_SPEED_2 = "playback_speed_2"
const PLAYBACK_SPEED_3 = "playback_speed_3"
const PLAYBACK_SPEED_4 = "playback_speed_4"
const TOGGLE_FLIP = "toggle_flip"
const ZOOM_IN = "zoom_in"
const ZOOM_OUT = "zoom_out"
const FREEZE_ON_READY = "freeze_on_ready"
const TOGGLE_AFTERIMAGES = "toggle_afterimages"
const TOGGLE_FREEZE_SOUND = "toggle_freeze_sound"
const TOGGLE_EXTRA_INFO = "toggle_extra_info"
const UNDO = "undo_action"
const SAVE_REPLAY = "save_replay"
# Held key (default SHIFT) that flips XY-plot snapping for as long as it's
# down. Previously hardcoded to KEY_SHIFT in XYPlot.gd, which is why it
# couldn't be rebound.
const XY_SNAP_OVERRIDE = "xy_snap_override"

const RUNTIME_DEFAULTS = {
	TOGGLE_HUD: KEY_F1,
	OPEN_CHAT: KEY_ENTER,
	SEND_CHAT: KEY_ENTER,
	TOGGLE_PREDICTIONS_MENU: 0,
	TOGGLE_NUDGE_MENU: 0,
	TOGGLE_FREE_CANCEL: 0,
	TOGGLE_PREDICTION: 0,
	TOGGLE_HITBOXES: 0,
	CLEAR_PARTICLES: 0,
	TOGGLE_PLAYBACK_CONTROLS: 0,
	TOGGLE_PROJECTILE_OWNERS: 0,
	RESET_ZOOM: 0,
	PREDICTION_SPEED_1: 0,
	PREDICTION_SPEED_HALF: 0,
	PREDICTION_SPEED_2: 0,
	PREDICTION_SPEED_3: 0,
	NUDGE_LEFT: KEY_LEFT,
	NUDGE_RIGHT: KEY_RIGHT,
	NUDGE_UP: KEY_UP,
	NUDGE_DOWN: KEY_DOWN,
	TOGGLE_FULLSCREEN: KEY_F11,
	PLAYBACK_SPEED_1: 0,
	PLAYBACK_SPEED_2: 0,
	PLAYBACK_SPEED_3: 0,
	PLAYBACK_SPEED_4: 0,
	TOGGLE_FLIP: 0,
	ZOOM_IN: KEY_EQUAL,
	ZOOM_OUT: KEY_MINUS,
	FREEZE_ON_READY: 0,
	TOGGLE_AFTERIMAGES: 0,
	TOGGLE_FREEZE_SOUND: 0,
	TOGGLE_EXTRA_INFO: 0,
	UNDO: KEY_Z | KEY_MASK_CTRL,
	SAVE_REPLAY: KEY_S | KEY_MASK_CTRL,
	XY_SNAP_OVERRIDE: KEY_SHIFT,
}

# Actions the user can rebind via the hotkeys settings UI.
# PAUSE/FOCUS_NEXT/ACCEPT/OPEN_DEBUG_PANEL are intentionally omitted - system keys.
const REBINDABLE = [
	{"action": TOGGLE_FULLSCREEN, "label": "Toggle Fullscreen"},
	{"action": LOCK_IN, "label": "Lock In"},
	{"action": WATCH_REPLAY, "label": "Watch Replay"},
	{"action": EDIT_REPLAY, "label": "Edit Replay"},
	{"action": FRAME_ADVANCE, "label": "Frame Advance"},
	{"action": TOGGLE_FRAME_ADVANCE, "label": "Toggle Frame Advance"},
	{"action": TOGGLE_HUD, "label": "Toggle HUD"},
	{"action": OPEN_CHAT, "label": "Open Chat"},
	{"action": TOGGLE_PREDICTIONS_MENU, "label": "Toggle Predictions Menu"},
	{"action": TOGGLE_NUDGE_MENU, "label": "Toggle Nudge Menu"},
	{"action": TOGGLE_FREE_CANCEL, "label": "Toggle Free Cancel"},
	{"action": TOGGLE_FLIP, "label": "Toggle Flip"},
	{"action": TOGGLE_PREDICTION, "label": "Toggle Prediction"},
	{"action": PREDICTION_SPEED_1, "label": "Prediction Speed x0.25"},
	{"action": PREDICTION_SPEED_HALF, "label": "Prediction Speed x0.5"},
	{"action": PREDICTION_SPEED_2, "label": "Prediction Speed x1"},
	{"action": PREDICTION_SPEED_3, "label": "Prediction Speed x2"},
	{"action": TOGGLE_HITBOXES, "label": "Toggle Hitboxes"},
	{"action": CLEAR_PARTICLES, "label": "Clear Particles"},
	{"action": TOGGLE_PLAYBACK_CONTROLS, "label": "Toggle Playback Controls"},
	{"action": PLAYBACK_SPEED_1, "label": "Playback Speed x0.25"},
	{"action": PLAYBACK_SPEED_2, "label": "Playback Speed x0.5"},
	{"action": PLAYBACK_SPEED_3, "label": "Playback Speed x0.75"},
	{"action": PLAYBACK_SPEED_4, "label": "Playback Speed x1"},
	{"action": TOGGLE_PROJECTILE_OWNERS, "label": "Toggle Projectile Owners"},
	{"action": TOGGLE_EXTRA_INFO, "label": "Toggle Extra Game Info"},
	{"action": RESET_ZOOM, "label": "Reset Zoom"},
	{"action": ZOOM_IN, "label": "Zoom In"},
	{"action": ZOOM_OUT, "label": "Zoom Out"},
	{"action": FREEZE_ON_READY, "label": "Toggle Freeze on Ready"},
	{"action": TOGGLE_AFTERIMAGES, "label": "Toggle Afterimages"},
	{"action": TOGGLE_FREEZE_SOUND, "label": "Toggle Freeze Sound"},
	{"action": UNDO, "label": "Undo"},
	{"action": SAVE_REPLAY, "label": "Save Replay"},
	{"action": XY_SNAP_OVERRIDE, "label": "XY Plot Snap Override (hold)"},
	{"action": NUDGE_LEFT, "label": "Nudge XY Plot Left"},
	{"action": NUDGE_RIGHT, "label": "Nudge XY Plot Right"},
	{"action": NUDGE_UP, "label": "Nudge XY Plot Up"},
	{"action": NUDGE_DOWN, "label": "Nudge XY Plot Down"},
]

# ESC is reserved as the "clear binding" gesture during rebind, so it can't be assigned.
const PROTECTED_KEYS = [KEY_ESCAPE]

var defaults = {}
var hovered_xy_plot = null

func _ready():
	for action in RUNTIME_DEFAULTS:
		if not is_action_enabled(action):
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var code = RUNTIME_DEFAULTS[action]
			if code != 0:
				InputMap.action_add_event(action, _make_event(code))
	for entry in REBINDABLE:
		if not is_action_enabled(entry.action):
			continue
		defaults[entry.action] = get_bound_scancode(entry.action)
	load_overrides()

# Scancodes are stored/passed around as "scancode with modifiers" — the base
# keycode OR'd with the KEY_MASK_* bits. OS.get_scancode_string renders that
# directly as e.g. "Control+Z", and InputEventKey carries the modifiers as
# bools, so these two helpers convert between the two representations.
func _event_code(ev: InputEventKey) -> int:
	var base = ev.scancode if ev.scancode != 0 else ev.physical_scancode
	var code = base
	if ev.control:
		code |= KEY_MASK_CTRL
	if ev.shift:
		code |= KEY_MASK_SHIFT
	if ev.alt:
		code |= KEY_MASK_ALT
	if ev.meta:
		code |= KEY_MASK_META
	return code

func _make_event(code: int) -> InputEventKey:
	var ev = InputEventKey.new()
	ev.scancode = code & KEY_CODE_MASK
	ev.control = (code & KEY_MASK_CTRL) != 0
	ev.shift = (code & KEY_MASK_SHIFT) != 0
	ev.alt = (code & KEY_MASK_ALT) != 0
	ev.meta = (code & KEY_MASK_META) != 0
	return ev

func get_display_name(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for ev in InputMap.get_action_list(action):
		if ev is InputEventKey:
			return _shorten_key_name(OS.get_scancode_string(_event_code(ev)))
	return ""

func _shorten_key_name(key_name: String) -> String:
	return key_name.replace("Escape", "Esc")

func get_bound_scancode(action: String) -> int:
	if not InputMap.has_action(action):
		return 0
	for ev in InputMap.get_action_list(action):
		if ev is InputEventKey:
			return _event_code(ev)
	return 0

# Protection is on the base keycode regardless of modifiers (so Ctrl+Esc is
# still treated as the reserved Esc gesture).
func is_protected_key(scancode: int) -> bool:
	return (scancode & KEY_CODE_MASK) in PROTECTED_KEYS

# Whether a known action is currently enabled. Lets us keep the REBINDABLE /
# RUNTIME_DEFAULTS const lists intact (so flipping a feature flag back on
# doesn't need a code change) while hiding the action from the rebind UI and
# from default InputMap registration when the flag is off.
func is_action_enabled(action: String) -> bool:
	if action == XY_SNAP_OVERRIDE and not Global.XY_SNAP_TOGGLE_ENABLED:
		return false
	return true

func clear_binding(action: String):
	if not InputMap.has_action(action):
		return
	for ev in InputMap.get_action_list(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	emit_signal("binding_changed", action)
	save_overrides()

func rebind(action: String, scancode: int) -> bool:
	if is_protected_key(scancode):
		return false
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for ev in InputMap.get_action_list(action):
		if ev is InputEventKey:
			InputMap.action_erase_event(action, ev)
	InputMap.action_add_event(action, _make_event(scancode))
	emit_signal("binding_changed", action)
	save_overrides()
	return true

func reset_to_defaults():
	for entry in REBINDABLE:
		if not is_action_enabled(entry.action):
			continue
		var action = entry.action
		var code = defaults.get(action, 0)
		for ev in InputMap.get_action_list(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		if code != 0:
			InputMap.action_add_event(action, _make_event(code))
		emit_signal("binding_changed", action)
	save_overrides()

func save_overrides():
	var data = {}
	for entry in REBINDABLE:
		if not is_action_enabled(entry.action):
			continue
		var action = entry.action
		data[action] = get_bound_scancode(action)
	Global.save_player_data({"hotkeys": data})

func load_overrides():
	var player_data = Global.get_player_data()
	if not (player_data is Dictionary):
		return
	if not ("hotkeys" in player_data):
		return
	var saved = player_data["hotkeys"]
	if not (saved is Dictionary):
		return
	for entry in REBINDABLE:
		if not is_action_enabled(entry.action):
			continue
		var action = entry.action
		if not (action in saved):
			continue
		var code = int(saved[action])
		for ev in InputMap.get_action_list(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		if code != 0:
			InputMap.action_add_event(action, _make_event(code))
