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
var touch_dragging = false
var touch_id = -1
var last_drag_pos = Vector2()
var last_emitted_value = -999999

const TOUCH_AREA_EXPANSION = 20.0

func _input(event: InputEvent):
	if Engine.editor_hint:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			var rect = _get_expanded_rect()
			if rect.has_point(event.position):
				touch_dragging = true
				touch_id = event.index
				last_drag_pos = event.position
				_update_from_screen_pos(event.position)
		else:
			if touch_dragging and event.index == touch_id:
				_update_from_screen_pos(last_drag_pos)
				touch_dragging = false
				touch_id = -1
				if buffer_value_changed:
					if !is_equal_approx($Direction.value, last_emitted_value):
						emit_signal("data_changed")
						last_emitted_value = $Direction.value
					buffer_value_changed = false
	elif event is InputEventScreenDrag:
		if touch_dragging and event.index == touch_id:
			last_drag_pos = event.position
			_update_from_screen_pos(event.position)
	elif event is InputEventMouseMotion:
		if mouse_clicked:
			_update_from_global_mouse()
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				var rect = _get_expanded_rect()
				if rect.has_point(get_global_mouse_position()):
					mouse_clicked = true
					_update_from_global_mouse()
			else:
				if mouse_clicked:
					_update_from_global_mouse()
				mouse_clicked = false
				if buffer_value_changed:
					if !is_equal_approx($Direction.value, last_emitted_value):
						emit_signal("data_changed")
						last_emitted_value = $Direction.value
					buffer_value_changed = false
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed and $Direction.get_rect().has_point(get_local_mouse_position()):
				$Direction.value = default
				if !is_equal_approx($Direction.value, last_emitted_value):
					emit_signal("data_changed")
					last_emitted_value = $Direction.value

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
			if !is_equal_approx($Direction.value, last_emitted_value):
				emit_signal("data_changed")
				last_emitted_value = $Direction.value
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
	if buffer_value_changed and !Input.is_mouse_button_pressed(BUTTON_LEFT) and not touch_dragging:
		if !is_equal_approx($Direction.value, last_emitted_value):
			emit_signal("data_changed")
			last_emitted_value = $Direction.value
		buffer_value_changed = false

func get_value():
	return int(round($Direction.value))

func get_data():
	return {
		"x": get_value()
	}
