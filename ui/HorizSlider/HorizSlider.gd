extends VBoxContainer

signal data_changed()

onready var default = $Direction.value

export var centered = true

# [ Range Fix ] inspector category (export_categories plugin renders _c_* as a
# header) — flags the opt-in below so it's obvious why it exists.
export var _c_EnableThisToUseMinAndMaxValue = 0
# Honor the top-node min_value/max_value below. These were historically dead:
# $Direction just kept whatever range its scene set, and characters were authored
# against that. Making them apply unconditionally (1.10) silently re-ranged every
# existing slider and broke a bunch of characters, so it's opt-in. OFF = legacy
# behavior (range comes from $Direction); turn ON for sliders that actually want
# the top-node range. Existing content stays untouched.
export var apply_top_node_range = false
export var _c_DisabledByDefaultForBackwardCompatibility = 0

export var min_value = 0
export var max_value = 100

var buffer_value_changed = false

var mouse_clicked = false
var mouse_pending = false
var mouse_start_pos = Vector2()
var touch_dragging = false
var touch_pending = false
var touch_id = -1
var touch_start_pos = Vector2()
var last_drag_pos = Vector2()
var last_emitted_value = -999999
var last_tap_time = 0.0
var last_tap_pos = Vector2()
var double_tap_pending = false

const TOUCH_AREA_EXPANSION = 20.0
const TOUCH_DRAG_THRESHOLD = 10.0
const DOUBLE_TAP_TIME = 0.3
const DOUBLE_TAP_DIST = 40.0

func _input(event: InputEvent):
	if Engine.editor_hint:
		return
	if not is_visible_in_tree():
		_reset_drag_state()
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			if Global.is_point_over_window(event.position, self):
				return
			_handle_touch_press(event)
		else:
			_handle_touch_release(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion()
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if Global.is_point_over_window(get_global_mouse_position(), self):
					return
				_handle_mouse_press()
			else:
				if mouse_clicked:
					_update_from_global_mouse()
				mouse_clicked = false
				mouse_pending = false
				_flush_buffer()
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed and not Global.is_point_over_window(get_global_mouse_position(), self) and $Direction.get_rect().has_point(get_local_mouse_position()):
				$Direction.value = default
				_emit_if_changed()

func _handle_touch_press(event: InputEventScreenTouch):
	if touch_id != -1 and event.index != touch_id:
		return
	var pos = event.position
	var rect = _get_expanded_rect()
	if rect.has_point(pos):
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_tap_time <= DOUBLE_TAP_TIME and pos.distance_to(last_tap_pos) <= DOUBLE_TAP_DIST:
			last_tap_time = 0.0
			double_tap_pending = true
			touch_id = event.index
			touch_dragging = false
			touch_pending = false
			return
		last_tap_time = now
		last_tap_pos = pos
		_begin_touch_drag(event.index, pos)

func _begin_touch_drag(index, pos):
	touch_pending = false
	touch_dragging = true
	touch_id = index
	last_drag_pos = pos
	_update_from_screen_pos(pos)

func _handle_touch_drag(event: InputEventScreenDrag):
	if event.index != touch_id:
		return
	if touch_pending:
		if event.position.distance_to(touch_start_pos) < TOUCH_DRAG_THRESHOLD:
			return
		touch_pending = false
		touch_dragging = true
	if not touch_dragging:
		return
	last_drag_pos = event.position
	_update_from_screen_pos(event.position)

func _handle_touch_release(event: InputEventScreenTouch):
	if event.index != touch_id:
		return
	if double_tap_pending:
		double_tap_pending = false
		touch_dragging = false
		touch_pending = false
		touch_id = -1
		$Direction.value = default
		_emit_if_changed()
		return
	if touch_dragging:
		_update_from_screen_pos(last_drag_pos)
	touch_dragging = false
	touch_pending = false
	touch_id = -1
	_flush_buffer()

func _handle_mouse_press():
	if touch_id != -1 or touch_dragging:
		return
	var pos = get_global_mouse_position()
	if $Direction.get_global_rect().has_point(pos):
		mouse_clicked = true
		_update_from_global_mouse()

func _handle_mouse_motion():
	if mouse_clicked:
		_update_from_global_mouse()
	elif mouse_pending and Input.is_mouse_button_pressed(BUTTON_LEFT):
		if get_global_mouse_position().distance_to(mouse_start_pos) >= TOUCH_DRAG_THRESHOLD:
			mouse_pending = false
			mouse_clicked = true
			_update_from_global_mouse()

func _flush_buffer():
	if buffer_value_changed:
		_emit_if_changed()
		buffer_value_changed = false

func _reset_drag_state():
	mouse_clicked = false
	mouse_pending = false
	touch_dragging = false
	touch_pending = false
	double_tap_pending = false
	touch_id = -1

func _emit_if_changed():
	var v = get_value()
	if v == int(round(last_emitted_value)):
		return
	emit_signal("data_changed")
	last_emitted_value = v

func _get_expanded_rect():
	var rect = $Direction.get_global_rect()
	return rect.grow(TOUCH_AREA_EXPANSION)

func _update_from_screen_pos(screen_pos):
	var local_pos = $Direction.get_global_rect().position
	var rect_size = $Direction.rect_size
	if rect_size.x <= 0:
		return
	var relative_x = screen_pos.x - local_pos.x
	var ratio = relative_x / rect_size.x
	ratio = clamp(ratio, 0.0, 1.0)
	var new_val = lerp($Direction.min_value, $Direction.max_value, ratio)
	_set_value_if_changed(new_val)

func _update_from_global_mouse():
	var global_pos = get_global_mouse_position()
	var local_pos = $Direction.get_global_rect().position
	var rect_size = $Direction.rect_size
	if rect_size.x <= 0:
		return
	var relative_x = global_pos.x - local_pos.x
	var ratio = relative_x / rect_size.x
	ratio = clamp(ratio, 0.0, 1.0)
	var new_val = lerp($Direction.min_value, $Direction.max_value, ratio)
	_set_value_if_changed(new_val)

func _set_value_if_changed(new_val):
	var old_val = $Direction.value
	$Direction.value = round(new_val) if abs(new_val - round(new_val)) < 0.5 else new_val
	if !is_equal_approx($Direction.value, old_val):
		buffer_value_changed = true
		if has_node("ValueLabel"):
			$ValueLabel.text = str(int(round($Direction.value)))
		if mouse_clicked or touch_dragging:
			_emit_if_changed()
			buffer_value_changed = false

func _ready():
	if apply_top_node_range:
		$Direction.min_value = min_value
		$Direction.max_value = max_value
	if !centered:
		$Direction.min_value = 0
	if has_node("Label"):
		$Label.text = name
	$Direction.connect("value_changed", self, "on_value_changed")
	last_emitted_value = $Direction.value

func on_value_changed(value):
	buffer_value_changed = true
	if has_node("ValueLabel"):
		$ValueLabel.text = str(int(round(value)))

func _process(_delta):
	if not is_visible_in_tree():
		_reset_drag_state()
		return
	if buffer_value_changed and not mouse_clicked and not mouse_pending and not touch_dragging and not touch_pending:
		_emit_if_changed()
		buffer_value_changed = false

func get_value():
	return int(round($Direction.value))

func get_data():
	return {
		"x": get_value()
	}
