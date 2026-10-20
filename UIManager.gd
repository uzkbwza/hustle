extends Node

const SIZE_SCALE = 1.25
const MIN_BUTTON_HEIGHT = 24
const MAX_BUTTON_HEIGHT = 32
const MIN_BUTTON_WIDTH = 24
const MIN_GAP = 2
const SCROLL_DRAG_THRESHOLD = 6.0

signal swiped_back()

var _menus = {}
var _elements = {}

var _mobile = false
var _force_button = null
var _drag_scroll = null
var _drag_active = false
var _drag_start = Vector2()
var _drag_last = Vector2()
var _drag_touch_id = -1

func _exit_tree():
	if is_inside_tree():
		var vp = get_viewport()
		if vp != null and vp.is_connected("size_changed", self, "_on_viewport_resized"):
			vp.disconnect("size_changed", self, "_on_viewport_resized")
	if get_tree().is_connected("node_added", self, "_on_force_button_added"):
		get_tree().disconnect("node_added", self, "_on_force_button_added")
	if Global.is_connected("mobile_ui_changed", self, "_on_mobile_ui_changed"):
		Global.disconnect("mobile_ui_changed", self, "_on_mobile_ui_changed")
	if Global.is_connected("option_changed", self, "_on_option_changed"):
		Global.disconnect("option_changed", self, "_on_option_changed")

func _ready():
	Global.connect("mobile_ui_changed", self, "_on_mobile_ui_changed")
	Global.connect("option_changed", self, "_on_option_changed")
	var vp = get_viewport()
	if vp != null and not vp.is_connected("size_changed", self, "_on_viewport_resized"):
		vp.connect("size_changed", self, "_on_viewport_resized")
	_mobile = Global.mobile_ui
	call_deferred("_find_force_button")

func _on_viewport_resized():
	if _mobile:
		_apply_all()

func register_menu(menu, elements: Array = []) -> void:
	if menu == null:
		return
	var id = menu.get_instance_id()
	if not _menus.has(id):
		_menus[id] = weakref(menu)
		if not menu.is_connected("tree_exiting", self, "_on_menu_exiting"):
			menu.connect("tree_exiting", self, "_on_menu_exiting", [id])
	for el in elements:
		_dispatch_element(el)
	for eid in _elements:
		var rec = _elements[eid]
		if rec.menu == 0 and _is_under(menu, rec):
			rec.menu = id
	_apply_menu(menu)

func _dispatch_element(el) -> void:
	var spec = _spec(el)
	if spec == null:
		return
	var node = spec.node
	if spec.kind != "":
		_add_element(node, spec.kind, spec.clamp, spec.weight, spec.position, spec.scale)
	elif node is Slider:
		scale_slider(node, spec.weight, spec.position, spec.scale)
	elif node is SpinBox:
		scale_spinbox(node, spec.weight, spec.position, spec.scale)
	elif node is LineEdit:
		scale_input(node, spec.weight, spec.position, spec.scale)
	elif node is BaseButton and not (node is TextureButton):
		scale_button(node, spec.weight, spec.position, spec.scale)
	elif node is BoxContainer:
		scale_gap(node, spec.weight, spec.position, spec.scale)
	elif node is Control:
		scale_control(node, spec.weight, spec.position, spec.scale)

func register_control(node: Control, elements: Array = []) -> void:
	for el in elements:
		_dispatch_element(el)
	if node != null:
		var rec = _elements.get(node.get_instance_id(), null)
		if rec != null:
			rec.menu = _owning_menu(node)

func unregister_menu(menu: Control) -> void:
	if menu == null:
		return
	var id = menu.get_instance_id()
	_menus.erase(id)
	_forget_elements_under(menu, true)

func _on_menu_exiting(id):
	_menus.erase(id)
	for eid in _elements.keys():
		if _elements[eid].menu == id:
			_elements[eid].menu = 0

func _is_under(menu, rec):
	var node = rec.node.get_ref()
	if node == null or menu == null:
		return false
	return menu == node or menu.is_a_parent_of(node)

func scale_button(node: BaseButton, weight := 1.0, position = null, rect_scale = null) -> void:
	_add_element(node, "min", true, weight, position, rect_scale)

func scale_slider(node: Slider, weight := 1.0, position = null, rect_scale = null) -> void:
	_add_element(node, "min", true, weight, position, rect_scale)

func scale_spinbox(node: SpinBox, weight := 1.0, position = null, rect_scale = null) -> void:
	_add_element(node, "min", true, weight, position, rect_scale)
	var line_edit = node.get_line_edit()
	if line_edit != null:
		scale_input(line_edit, weight, position, rect_scale)

func scale_input(node: LineEdit, weight := 1.0, position = null, rect_scale = null) -> void:
	_add_element(node, "min", true, weight, position, rect_scale)

func scale_control(node: Control, weight := 1.0, position = null, rect_scale = null) -> void:
	_add_element(node, "min", false, weight, position, rect_scale)

func scale_gap(node: BoxContainer, weight := 1.0, position = null, rect_scale = null) -> void:
	_add_element(node, "gap", false, weight, position, rect_scale)

func reapply_menu(menu: Control) -> void:
	if menu == null:
		return
	var id = menu.get_instance_id()
	for eid in _elements:
		var rec = _elements[eid]
		if rec.menu == id or _is_under(menu, rec):
			rec.menu = id
			if _mobile:
				_apply_element(rec)
			else:
				_restore_element(rec)

func set_menu_weight(menu: Control, weight: float) -> void:
	if menu == null:
		return
	var id = menu.get_instance_id()
	for eid in _elements:
		var rec = _elements[eid]
		if rec.menu == id or _is_under(menu, rec):
			rec.menu = id
			rec.weight = weight
			if _mobile:
				_apply_element(rec)

func _spec(el):
	if el == null:
		return null
	var spec = {
		"node": null,
		"kind": "",
		"clamp": false,
		"weight": 1.0,
		"position": null,
		"scale": null,
	}
	if el is Dictionary:
		spec.node = el.get("node", null)
		spec.kind = el.get("kind", "")
		spec.weight = float(el.get("weight", 1.0))
		spec.position = _as_vector2(el.get("position", null))
		spec.scale = _as_vector2(el.get("scale", el.get("rect_scale", null)))
		if not el.has("kind") and el.has("clamp"):
			spec.clamp = bool(el.get("clamp"))
	elif el is Control:
		spec.node = el
	else:
		return null
	if spec.node == null or not is_instance_valid(spec.node):
		return null
	if spec.kind != "":
		spec.clamp = spec.kind == "min" and spec.node is BaseButton
	elif spec.node is Slider or spec.node is SpinBox or spec.node is LineEdit or (spec.node is BaseButton and not (spec.node is TextureButton)):
		spec.clamp = true
	return spec

func _as_vector2(value):
	if value == null:
		return null
	if value is Vector2:
		return value
	if value is Array and value.size() == 2:
		return Vector2(value[0], value[1])
	if value is int or value is float:
		return Vector2(value, value)
	return null

func _add_element(node, kind, use_clamp: bool, weight: float, position = null, rect_scale = null):
	if node == null or not is_instance_valid(node):
		return
	var id = node.get_instance_id()
	var rec = _elements.get(id)
	if rec == null:
		rec = {
			"node": weakref(node),
			"kind": kind,
			"clamp": use_clamp,
			"menu": 0,
			"weight": weight,
			"scale": rect_scale,
			"position": position,
			"orig": _read_orig(node, kind),
			"orig_pos": node.rect_position if node is Control else Vector2(),
			"nudged": false,
		}
		if node is Control:
			rec["orig_size"] = node.rect_size
			rec["orig_margin"] = Rect2(node.margin_left, node.margin_top, node.margin_right, node.margin_bottom)
		_elements[id] = rec
		if not node.is_connected("tree_exiting", self, "_on_element_exiting"):
			node.connect("tree_exiting", self, "_on_element_exiting", [id])
		if node is Control and not node.is_connected("resized", self, "_on_element_resized"):
			node.connect("resized", self, "_on_element_resized", [id])
	else:
		rec.weight = weight
		if rect_scale != null:
			rec.scale = rect_scale
		if position != null:
			rec.position = position
	if rec.menu == 0:
		rec.menu = _owning_menu(node)
	if _mobile:
		_apply_element(rec)

func _read_orig(node, kind):
	if kind == "gap":
		return float(node.get_constant("separation"))
	return node.rect_min_size

func _owning_menu(node):
	var n = node
	while n != null:
		var id = n.get_instance_id()
		if _menus.has(id):
			return id
		n = n.get_parent()
	return 0

func _on_element_exiting(id):
	_elements.erase(id)

func _forget_elements_under(menu, restore: bool):
	for eid in _elements.keys():
		var rec = _elements[eid]
		var node = rec.node.get_ref()
		if node == null or node == menu or (menu != null and menu.is_a_parent_of(node)):
			if restore:
				_restore_element(rec)
			_elements.erase(eid)

func _apply_menu(menu):
	for eid in _elements:
		var rec = _elements[eid]
		if rec.menu == menu.get_instance_id() or _is_under(menu, rec):
			rec.menu = menu.get_instance_id()
			if _mobile:
				_apply_element(rec)

func _apply_all():
	for eid in _elements:
		_apply_element(_elements[eid])

func _restore_all():
	for eid in _elements:
		_restore_element(_elements[eid])
	for eid in _elements:
		var rec = _elements[eid]
		var node = rec.node.get_ref()
		if node != null and is_instance_valid(node) and node is Control and rec.has("orig_size"):
			_restore_size(node, rec.orig_size)

func _apply_element(rec):
	var node = rec.node.get_ref()
	if node == null or not is_instance_valid(node):
		return
	if rec.kind == "gap":
		var orig = float(rec.orig)
		var target = max(orig * SIZE_SCALE, MIN_GAP)
		var sep = int(round(orig + (target - orig) * rec.weight))
		node.add_constant_override("separation", sep)
		_apply_position(rec, node)
		return
	var orig = rec.orig
	if not (orig is Vector2):
		return
	node.rect_min_size = orig
	var combined = node.get_combined_minimum_size()
	var gain = Vector2(SIZE_SCALE, SIZE_SCALE)
	var target
	if rec.clamp:
		var min_x = max(combined.x, MIN_BUTTON_WIDTH)
		var min_y = clamp(combined.y * gain.y, MIN_BUTTON_HEIGHT, MAX_BUTTON_HEIGHT)
		target = Vector2(max(min_x, orig.x), max(min_y, orig.y))
	else:
		target = Vector2(max(combined.x * gain.x, orig.x), max(combined.y * gain.y, orig.y))
	var scaled = orig + (target - orig) * rec.weight
	if rec.scale != null:
		scaled = Vector2(scaled.x * rec.scale.x, scaled.y * rec.scale.y)
	scaled = _fit_size_to_parent(node, scaled, orig)
	node.rect_min_size = scaled
	_apply_position(rec, node)

func _fit_size_to_parent(node, size: Vector2, orig) -> Vector2:
	var bounds = _parent_bounds(node)
	if bounds != null:
		if size.x > bounds.x:
			size.x = max(bounds.x, orig.x)
		if size.y > bounds.y:
			size.y = max(bounds.y, orig.y)
	return size

func _apply_position(rec, node):
	if not (node is Control):
		return
	if rec.position != null:
		node.rect_position = rec.position
	elif _has_registered_ancestor(node):
		return
	elif _layout_managed(node):
		return
	elif _recenter_anchored(node, rec):
		return
	_clamp_to_screen(node, rec)

func _recenter_anchored(node, rec) -> bool:
	if abs(node.anchor_left - 0.5) >= 0.01 or abs(node.anchor_right - 0.5) >= 0.01 or abs(node.anchor_top - 0.5) >= 0.01 or abs(node.anchor_bottom - 0.5) >= 0.01:
		return false
	var margin = rec.get("orig_margin", Rect2(node.margin_left, node.margin_top, node.margin_right, node.margin_bottom))
	var h_centered = abs(margin.position.x + margin.size.x) < 0.01
	var v_centered = abs(margin.position.y + margin.size.y) < 0.01
	if not h_centered and not v_centered:
		return false
	var parent_rect = node.get_parent().get_rect() if node.get_parent() is Control else node.get_viewport().get_visible_rect()
	var center = parent_rect.position + parent_rect.size * 0.5
	var pos = node.rect_position
	if h_centered:
		pos.x = center.x - node.rect_size.x * 0.5
	if v_centered:
		pos.y = center.y - node.rect_size.y * 0.5
	if pos != node.rect_position:
		node.rect_position = pos
	return true

func _layout_managed(node):
	var n = node.get_parent()
	while n != null and n != get_tree().root:
		if n is Container:
			return true
		n = n.get_parent()
	return false

func _clamp_to_screen(node, rec):
	if not node.is_inside_tree():
		return
	var vp = node.get_viewport()
	if vp == null:
		return
	var screen = vp.get_visible_rect()
	var rect = node.get_global_rect()
	var max_pos = screen.position + screen.size - rect.size
	var target = rect.position
	target.x = clamp(target.x, screen.position.x, max(screen.position.x, max_pos.x))
	target.y = clamp(target.y, screen.position.y, max(screen.position.y, max_pos.y))
	if target != rect.position:
		node.rect_global_position = target
		rec.nudged = true

func _has_registered_ancestor(node):
	var n = node.get_parent()
	while n != null and n != get_tree().root:
		if _elements.has(n.get_instance_id()):
			return true
		n = n.get_parent()
	return false

func _on_element_resized(id):
	if not _mobile:
		return
	var rec = _elements.get(id)
	if rec == null:
		return
	var node = rec.node.get_ref()
	if node != null and is_instance_valid(node):
		_apply_position(rec, node)

func _parent_bounds(node):
	var parent = node.get_parent()
	if parent is Control and not (parent is Container) and parent.rect_size.x > 0 and parent.rect_size.y > 0:
		return parent.rect_size
	return null

func _restore_element(rec):
	var node = rec.node.get_ref()
	if node == null or not is_instance_valid(node):
		return
	if rec.kind == "gap":
		node.remove_constant_override("separation")
		if node.get_constant("separation") != rec.orig:
			node.add_constant_override("separation", rec.orig)
	else:
		if rec.orig is Vector2:
			node.rect_min_size = rec.orig
	if (rec.position != null or rec.nudged) and node is Control:
		node.rect_position = rec.orig_pos
		rec.nudged = false

func _restore_size(node, orig_size):
	if _layout_managed(node):
		return
	if node.rect_size != orig_size:
		node.rect_size = orig_size

func _on_mobile_ui_changed(mobile):
	if _mobile == mobile:
		return
	_mobile = mobile
	if mobile:
		_apply_all()
	else:
		_restore_all()
	_update_force_button()

func _on_option_changed(option, value):
	if option == "force_alt_ui":
		_update_force_button()

func _update_force_button():
	var btn = _force_button.get_ref() if _force_button else null
	if btn and is_instance_valid(btn):
		btn.set_pressed_no_signal(Global.force_alt_ui)
		var alt_text = "desktop" if Global.mobile_ui else "mobile"
		btn.text = "force " + alt_text + " ui layout"

func hide_on_device(node: CanvasItem) -> void:
	if node != null and Global.is_mobile_device:
		node.visible = false

func _find_force_button():
	var btn = get_node_or_null("%ForceAltUIButton")
	if not btn:
		btn = _find_named(get_tree().root, "ForceAltUIButton")
	if btn:
		_force_button = weakref(btn)
		_update_force_button()
	else:
		_force_button = null
		if not get_tree().is_connected("node_added", self, "_on_force_button_added"):
			get_tree().connect("node_added", self, "_on_force_button_added")

func _find_named(node, node_name):
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_named(child, node_name)
		if found:
			return found
	return null

func _on_force_button_added(node):
	if node.name == "ForceAltUIButton" and node is CheckButton:
		get_tree().disconnect("node_added", self, "_on_force_button_added")
		_force_button = weakref(node)
		_update_force_button()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
#		var ev = InputEventKey.new()
#		ev.scancode = KEY_ESCAPE
#		ev.physical_scancode = KEY_ESCAPE
#		ev.pressed = true
#		Input.parse_input_event(ev)
		emit_signal("swiped_back")

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if _drag_touch_id == -1:
				_drag_touch_id = event.index
				_begin_drag(event.position)
		elif event.index == _drag_touch_id:
			_drag_touch_id = -1
			_end_drag()
	elif event is InputEventScreenDrag:
		if event.index == _drag_touch_id:
			_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventMouseMotion and _drag_scroll != null:
		if event.button_mask & BUTTON_MASK_LEFT:
			_update_drag(event.position)
		else:
			_reset_drag()

func _begin_drag(pos):
	_drag_active = false
	_drag_start = pos
	_drag_last = pos
	var sc = _find_scroll_at(pos)
	if sc == null or _on_scrollbar(sc, pos) or _interactive_at(sc, pos) != null:
		_drag_scroll = null
		return
	_drag_scroll = sc

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
	if node is Slider or node is SpinBox or node is LineEdit:
		return true
	var script = node.get_script()
	if script != null:
		if script.has_method("_handle_touch_drag") or script.has_method("_handle_drag_event"):
			return true
	if node.has_method("get_value") or node.has_method("get_data"):
		return true
	return false

func _on_scrollbar(sc, pos):
	var vs = sc.get_v_scrollbar()
	if vs != null and vs.is_visible_in_tree() and vs.get_global_rect().has_point(pos):
		return true
	var hs = sc.get_h_scrollbar()
	if hs != null and hs.is_visible_in_tree() and hs.get_global_rect().has_point(pos):
		return true
	return false

func _update_drag(pos):
	if _drag_scroll == null or not is_instance_valid(_drag_scroll):
		_reset_drag()
		return
	if not _drag_active and pos.distance_to(_drag_start) > SCROLL_DRAG_THRESHOLD:
		_drag_active = true
	if _drag_active:
		_drag_scroll.scroll_horizontal -= int(pos.x - _drag_last.x)
		_drag_scroll.scroll_vertical -= int(pos.y - _drag_last.y)
		_drag_last = pos
		get_tree().set_input_as_handled()

func _end_drag():
	if _drag_active:
		get_tree().set_input_as_handled()
	_reset_drag()

func _reset_drag():
	_drag_scroll = null
	_drag_active = false

func _find_scroll_at(pos):
	var best = null
	var best_depth = -1
	var stack = [[get_tree().root, 0]]
	while not stack.empty():
		var entry = stack.pop_back()
		var node = entry[0]
		var depth = entry[1]
		if node is ScrollContainer and node.is_visible_in_tree():
			if node.get_global_rect().has_point(pos) and depth > best_depth:
				best = node
				best_depth = depth
		for child in node.get_children():
			stack.append([child, depth + 1])
	return best
