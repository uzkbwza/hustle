extends Control

class_name Window

var drag_position

onready var window_contents = $VBoxContainer/Contents

export var static_ = false

var _touch_id = -1

func _ready():
	hint_tooltip = name
	connect("draw", self, "snap_to_boundaries")

func _input(event: InputEvent):
	if static_ or not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			if _can_drag_at(event.position):
				drag_position = get_global_mouse_position() - rect_global_position
				raise()
		else:
			drag_position = null
	elif event is InputEventScreenTouch:
		if event.pressed:
			if _touch_id == -1 and _can_drag_at(event.position):
				_touch_id = event.index
				drag_position = event.position - rect_global_position
				raise()
		elif event.index == _touch_id:
			_touch_id = -1
			drag_position = null
	elif event is InputEventMouseMotion and drag_position != null:
		if event.button_mask & BUTTON_MASK_LEFT:
			rect_global_position = get_global_mouse_position() - drag_position
			snap_to_boundaries()
	elif event is InputEventScreenDrag:
		if event.index == _touch_id:
			rect_global_position = event.position - drag_position
			snap_to_boundaries()
			get_tree().set_input_as_handled()

func _can_drag_at(pos: Vector2) -> bool:
	if not get_global_rect().has_point(pos):
		return false
	return _interactive_at(self, pos) == null

func _interactive_at(root, pos):
	if not (root is Control) or not root.is_visible_in_tree():
		return null
	if root.get_global_rect().has_point(pos) and _consumes_drag(root):
		return root
	for child in root.get_children():
		var found = _interactive_at(child, pos)
		if found != null:
			return found
	return null

func _consumes_drag(node) -> bool:
	if node is BaseButton or node is Slider or node is SpinBox or node is LineEdit or node is ScrollContainer or node is Tabs:
		return true
	if node.has_method("get_data") or node.has_method("get_value"):
		return true
	return false

func snap_to_boundaries():
	var viewport_size = get_viewport_rect().size
	if rect_global_position.x < 0:
		rect_global_position.x = 0
	if rect_global_position.y < 0:
		rect_global_position.y = 0
	if rect_global_position.x + rect_size.x > viewport_size.x:
		rect_global_position.x = viewport_size.x - rect_size.x
	if rect_global_position.y + rect_size.y > viewport_size.y:
		rect_global_position.y = viewport_size.y - rect_size.y
