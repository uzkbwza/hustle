extends Node

const SIZE_SCALE = 1.25
const VIEWPORT_W = 640
const VIEWPORT_H = 360
const MIN_BUTTON_HEIGHT = 24
const MAX_BUTTON_HEIGHT = 32
const MIN_BUTTON_WIDTH = 24
const MIN_GAP = 2
const SCROLL_DRAG_THRESHOLD = 6.0

const WHITELIST = ["PausePanel"]
const BLACKLIST = [
	"SteamLobby", "Credits", "SteamLobbyList", "SuperDim", "P1SuperTexture", "P2SuperTexture",
	"WinLabel", "ExtraInfoContainer", "BgCircle", "DebugContainer", "ButtonSoundPlayer", "TurnButtons",
	"HudLayer", "ColorPickers", "SoupModOptionsWarning", "CharLoaderWarning", "ModMissingContainer",
	"ModInfoContainer", "ModListContainer", "Lobby", "TitleBar", "DirectConnectLobby",
]
const BLACKLIST_CANVAS_ONLY = ["SteamLobby", "Credits", "SteamLobbyList"]

signal swiped_back()

var _originals = {}
var _mobile = false
var _force_button = null
var _pending_added = []
var _flush_queued = false
var _drag_scroll = null
var _drag_active = false
var _drag_start = Vector2()
var _drag_last = Vector2()
var _next_sweep = 3000
var _new_record_count = 0
var _skip_cache = {}
var _sorted_pass = {}
var _base_cache = {}

func _enter_tree():
	get_tree().connect("node_added", self, "_on_node_added")
	get_tree().connect("node_removed", self, "_on_node_removed")

func _exit_tree():
	get_tree().disconnect("node_added", self, "_on_node_added")
	get_tree().disconnect("node_removed", self, "_on_node_removed")
	if get_tree().is_connected("node_added", self, "_on_force_button_added"):
		get_tree().disconnect("node_added", self, "_on_force_button_added")
	if Global.is_connected("mobile_ui_changed", self, "_on_mobile_ui_changed"):
		Global.disconnect("mobile_ui_changed", self, "_on_mobile_ui_changed")
	if Global.is_connected("option_changed", self, "_on_option_changed"):
		Global.disconnect("option_changed", self, "_on_option_changed")

func _ready():
	Global.connect("mobile_ui_changed", self, "_on_mobile_ui_changed")
	Global.connect("option_changed", self, "_on_option_changed")
	_mobile = Global.mobile_ui
	call_deferred("_delayed_apply_all")
	call_deferred("_find_force_button")

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

func _on_node_removed(node):
	if node == _drag_scroll:
		_drag_scroll = null
		_drag_active = false
	_base_cache.clear()
	_skip_cache.clear()
	if _force_button and _force_button.get_ref() == node:
		_force_button = null
		call_deferred("_find_force_button")

func _maybe_sweep():
	if _originals.size() > _next_sweep:
		_sweep_originals()
		_next_sweep = _originals.size() + 3000

func _sweep_originals():
	var dead = []
	for id in _originals:
		var rec = _originals[id]
		if not rec.node or rec.node.get_ref() == null:
			dead.append(id)
	for id in dead:
		_originals.erase(id)

func _delayed_apply_all():
	var attempts := 0
	while attempts < 3:
		yield(get_tree(), "idle_frame")
		_mobile = Global.mobile_ui
		_apply_all()
		attempts += 1

func _on_option_changed(option, value):
	if option == "force_alt_ui":
		_update_force_button()

func _update_force_button():
	var btn = _force_button.get_ref() if _force_button else null
	if btn and is_instance_valid(btn):
		btn.set_pressed_no_signal(Global.force_alt_ui)
		var alt_text = "desktop" if Global.mobile_ui else "mobile"
		btn.text = "force " + alt_text + " ui layout"

func _on_mobile_ui_changed(mobile):
	if _mobile == mobile:
		return
	_mobile = mobile
	if mobile:
		call_deferred("_apply_all")
	else:
		call_deferred("_restore_all")
	_update_force_button()

func _on_node_added(node):
	if Global.is_mobile_device and _is_device_hidden_button(node):
		node.visible = false
	if not _mobile:
		if node.get_instance_id() in _originals:
			_restore_node(_originals[node.get_instance_id()])
		return
	if not node is Control:
		return
	if _skip_subtree(node):
		return
	_pending_added.append(node)
	if _flush_queued:
		return
	_flush_queued = true
	call_deferred("_flush_added")

func _flush_added():
	_flush_queued = false
	var nodes = _pending_added
	_pending_added = []
	if not _mobile or nodes.empty():
		return
	var owners = {}
	for n in nodes:
		if not is_instance_valid(n):
			continue
		var owner = n if (_is_root(n) or _is_self_grown(n)) else _root_of(n)
		if owner == null:
			owner = n
		owners[owner.get_instance_id()] = owner
	for id in owners:
		_apply_subtree(owners[id])

func _root_of(node):
	var n = node.get_parent()
	while n and n != get_tree().root:
		if _is_root(n) or _is_self_grown(n):
			return n
		n = n.get_parent()
	return null

func _apply_all():
	if not _mobile:
		return
	_apply_subtree(get_tree().root)

func _apply_subtree(node):
	if not _mobile:
		return
	if not is_instance_valid(node):
		return
	_sorted_pass = {}
	_capture_subtree(node)
	_layout_subtree(node)

func _capture_subtree(node):
	var is_control = node is Control
	if is_control:
		if _skip_subtree(node):
			return
		_ensure_record(node)
	for child in node.get_children():
		_capture_subtree(child)

func _layout_subtree(node):
	var is_control = node is Control
	if is_control:
		if _skip_subtree(node):
			return
	for child in node.get_children():
		_layout_subtree(child)
	if is_control:
		_apply_node(node)

func _ensure_record(node):
	var id = node.get_instance_id()
	if not (id in _originals):
		_originals[id] = _capture(node)
		_base_cache.clear()
		_new_record_count += 1
		if _new_record_count > 128:
			_new_record_count = 0
			_maybe_sweep()

func _apply_node(node):
	var id = node.get_instance_id()
	var record = _originals[id]
	_restore_node(record)
	_modify(node, record)
	record.active = true
	if _is_self_grown(node):
		_regrow_self(node)

func _capture(node):
	var record = {}
	record.node = weakref(node)
	if (node is BaseButton and not (node is TextureButton)) or node is LineEdit or _is_icon_button(node) or node is Slider:
		record.orig_min = node.rect_min_size
	elif node is BoxContainer:
		record.orig_sep = node.get_constant("separation")
	elif node is Control and not (node is Container) and _self_grown_child(node) != null:
		record.orig_min = node.rect_min_size
		record.orig_size = node.rect_size
		record.grow_parent = true
	if _is_root(node) or _is_self_grown(node) or _is_plain_root_child(node):
		record.orig_margin_left = node.margin_left
		record.orig_margin_top = node.margin_top
		record.orig_margin_right = node.margin_right
		record.orig_margin_bottom = node.margin_bottom
		record.orig_clip = node.rect_clip_content
		record.orig_rect = Rect2(node.rect_position, node.rect_size)
	return record

func _modify(node, record):
	if (node is BaseButton and not (node is TextureButton)) or node is LineEdit or _is_icon_button(node) or node is Slider:
		var combined = node.get_combined_minimum_size()
		var min_x = max(combined.x, MIN_BUTTON_WIDTH)
		var min_y = clamp(combined.y * SIZE_SCALE, MIN_BUTTON_HEIGHT, MAX_BUTTON_HEIGHT)
		record.mod_min = Vector2(max(min_x, record.orig_min.x), max(min_y, record.orig_min.y))
		node.rect_min_size = record.mod_min
	elif node is BoxContainer:
		record.mod_sep = max(record.orig_sep * SIZE_SCALE, MIN_GAP)
		node.add_constant_override("separation", record.mod_sep)
	elif "grow_parent" in record:
		_grow_parent_to_fit(node, _self_grown_child(node))
	if _is_root(node):
		_apply_root(node, record)

func _is_device_hidden_button(node):
	if not (node is BaseButton):
		return false
	if node.name == "SteamMultiplayerButton":
		return true

func _whitelisted(node):
	if node.name in WHITELIST:
		return true
	for pattern in WHITELIST:
		if node.name.match(pattern):
			return true
	return false

func _blacklisted(node):
	var nm = node.name
	if nm in BLACKLIST:
		if nm in BLACKLIST_CANVAS_ONLY:
			return node.get_parent() is CanvasLayer
		return true
	for pattern in BLACKLIST:
		if nm.match(pattern):
			return true
	return false

func _skip_subtree(node):
	var id = node.get_instance_id()
	if id in _skip_cache:
		var cached = _skip_cache[id]
		if cached == true:
			return true
		if cached == false:
			return false
	var n = node
	while n and n != get_tree().root:
		if _whitelisted(n):
			_skip_cache[id] = false
			return false
		if n is ActionUIData:
			_skip_cache[id] = false
			return false
		if n is ActionButtons:
			_skip_cache[id] = true
			return true
		if n is Game:
			_skip_cache[id] = true
			return true
		if n.name == "GameUI":
			var res = (n != node)
			_skip_cache[id] = res
			return res
		if _blacklisted(n):
			_skip_cache[id] = true
			return true
		n = n.get_parent()
	_skip_cache[id] = false
	return false

func _is_root(node):
	if node is Window:
		return true
	if node.get_parent() is CanvasLayer:
		if node.name in ["GameUI", "HudLayer", "SuperDim", "P1SuperTexture", "P2SuperTexture", "WinLabel", "ExtraInfoContainer", "BgCircle", "DebugContainer", "ButtonSoundPlayer"]:
			return false
		return true
	if node.name == "PausePanel":
		return true
	return false

func _is_self_grown(node):
	if _is_root(node):
		return false
	if not (node is Container):
		return false
	var p = node.get_parent()
	if p == null or p == get_tree().root:
		return false
	if not (p is Control):
		return false
	if p is Container or _is_root(p):
		return false
	return true

func _is_plain_root_child(node):
	var p = node.get_parent()
	if p == null:
		return false
	if not _is_root(p):
		return false
	return not (p is Container)

func _is_growable(node):
	if node is Container:
		return true
	return (node is BaseButton and not (node is TextureButton)) or node is LineEdit or _is_icon_button(node) or node is Slider

func _is_icon_button(node):
	if not (node is TextureButton):
		return false
	var p = node.get_parent()
	return p != null and p.name == "TitleBar"

func _self_grown_child(node):
	for c in node.get_children():
		if c is Container and _is_self_grown(c):
			return c
	return null

func _grow_parent_to_fit(parent, child):
	if child == null or not (parent is Control) or parent is Container or _is_root(parent):
		return
	var pid = parent.get_instance_id()
	if not (pid in _originals):
		return
	var rec = _originals[pid]
	if not ("grow_parent" in rec):
		return
	var base = _base_min(child)
	_apply_scale(child, 1.0)
	if base.x > rec.orig_size.x + 0.01 or base.y > rec.orig_size.y + 0.01:
		return
	var combined = child.get_combined_minimum_size()
	var nm = Vector2(max(rec.orig_min.x, combined.x), max(rec.orig_min.y, combined.y))
	rec.mod_min = nm
	if parent.rect_min_size != nm:
		parent.rect_min_size = nm
	if parent.rect_size.x < nm.x or parent.rect_size.y < nm.y:
		parent.rect_size = Vector2(max(parent.rect_size.x, nm.x), max(parent.rect_size.y, nm.y))

func _base_min(node):
	var id = node.get_instance_id()
	if id in _base_cache:
		return _base_cache[id]
	_apply_scale(node, 0.0)
	var base = node.get_combined_minimum_size()
	_apply_scale(node, 1.0)
	_base_cache[id] = base
	return base

func _apply_root(node, record):
	if node is Container:
		_grow_container_root(node)
	else:
		_reflow_plain_root(node)

func _grow_container_root(node):
	var combined = node.get_combined_minimum_size()
	var new_size = Vector2(min(max(node.rect_size.x, combined.x), VIEWPORT_W), min(max(node.rect_size.y, combined.y), VIEWPORT_H))
	if new_size != node.rect_size:
		_position_centered(node, new_size)
		node.rect_size = new_size
	if new_size.x == VIEWPORT_W or new_size.y == VIEWPORT_H:
		node.rect_clip_content = true
	_clamp_position(node)
	_force_sort(node)
	var sibling_bounds = _collect_sibling_bounds(node)
	for child in node.get_children():
		if child is Control and _is_growable(child) and not _is_root(child):
			_fit_to_band(node, child, sibling_bounds)

func _reflow_plain_root(node):
	for child in node.get_children():
		if child is Control and _is_growable(child):
			_grow_to_combined(child)
	_grow_plain_root_to_fit(node)
	_force_sort(node)
	var sibling_bounds = _collect_sibling_bounds(node)
	for child in node.get_children():
		if child is Control and _is_growable(child) and not _is_root(child):
			_fit_to_band(node, child, sibling_bounds)
	for child in node.get_children():
		if child is Control:
			_clamp_child_into_parent(child, node)
	_grow_plain_root_to_fit(node)
	for child in node.get_children():
		if child is Control:
			_clamp_child_into_parent(child, node)

func _regrow_self(node):
	_grow_to_combined(node)
	var p = node.get_parent()
	if p == null or not (p is Control):
		return
	_grow_parent_to_fit(p, node)
	_force_sort(p)
	_fit_to_band(p, node, _collect_sibling_bounds(p))
	_clamp_child_into_parent(node, p)

func _grow_to_combined(node):
	var combined = node.get_combined_minimum_size()
	var new_size = Vector2(max(node.rect_size.x, combined.x), max(node.rect_size.y, combined.y))
	if new_size != node.rect_size:
		_position_centered(node, new_size)
		node.rect_size = new_size

func _position_centered(node, new_size):
	var old_size = node.rect_size
	var pos = node.rect_position
	if abs(node.anchor_left - 0.5) < 0.01 and abs(node.anchor_right - 0.5) < 0.01:
		pos.x += (old_size.x - new_size.x) / 2.0
	if abs(node.anchor_top - 0.5) < 0.01 and abs(node.anchor_bottom - 0.5) < 0.01:
		pos.y += (old_size.y - new_size.y) / 2.0
	node.rect_position = pos

func _grow_plain_root_to_fit(node):
	var needed = Vector2(0.0, 0.0)
	for child in node.get_children():
		if child is Control:
			needed.x = max(needed.x, child.rect_position.x + child.rect_size.x)
			needed.y = max(needed.y, child.rect_position.y + child.rect_size.y)
	needed.x = min(needed.x, VIEWPORT_W)
	needed.y = min(needed.y, VIEWPORT_H)
	var new_size = Vector2(max(node.rect_size.x, needed.x), max(node.rect_size.y, needed.y))
	if new_size == node.rect_size:
		return
	_position_centered(node, new_size)
	node.rect_size = new_size
	if needed.x >= VIEWPORT_W or needed.y >= VIEWPORT_H:
		node.rect_clip_content = true
	_clamp_position(node)

func _fit_to_band(ctx, child, sibling_bounds):
	if not _is_growable(child):
		return
	if ctx.rect_size.x < 16.0 or ctx.rect_size.y < 16.0:
		return
	var band = _compute_band(ctx, child, sibling_bounds)
	var pos = child.rect_position
	var size = child.rect_size
	if pos.x >= band.position.x - 0.01 and pos.y >= band.position.y - 0.01 and pos.x + size.x <= band.end.x + 0.01 and pos.y + size.y <= band.end.y + 0.01:
		return
	if size.x > band.size.x + 0.01 or size.y > band.size.y + 0.01:
		var s = _shrink_to_fit(child, band)
		if s < 0.999:
			var cur = child.rect_size
			var new_size = Vector2(min(cur.x, band.size.x), min(cur.y, band.size.y))
			if new_size != cur:
				child.rect_size = new_size
				child.rect_clip_content = true
	_position_in_band(child, band)

func _compute_band(ctx, child, sibling_bounds: Array):
	var full = Rect2(Vector2(), ctx.rect_size)
	var vb = _visual_bounds(child, ctx)
	if vb.size.x < 1.0 or vb.size.y < 1.0:
		return full
	var min_p = Vector2(0.0, 0.0)
	var max_p = ctx.rect_size
	var c1 = vb.position + vb.size * 0.5
	var orc = null
	var cid = child.get_instance_id()
	if cid in _originals and "orig_rect" in _originals[cid]:
		orc = _originals[cid].orig_rect
	for i in range(ctx.get_child_count()):
		var other = ctx.get_child(i)
		if other == child or not (other is Control) or not other.visible or _is_root(other):
			continue
		var ob = sibling_bounds[i]
		if ob.size.x < 1.0 or ob.size.y < 1.0:
			continue
		var c2 = ob.position + ob.size * 0.5
		var dx = c2.x - c1.x
		var dy = c2.y - c1.y
		var gap_x = MIN_GAP
		var gap_y = MIN_GAP
		if orc != null:
			var oid = other.get_instance_id()
			if oid in _originals and "orig_rect" in _originals[oid]:
				var oorc = _originals[oid].orig_rect
				gap_x = min(float(MIN_GAP), (oorc.position.x - orc.end.x) if dx >= 0.0 else (orc.position.x - oorc.end.x))
				gap_y = min(float(MIN_GAP), (oorc.position.y - orc.end.y) if dy >= 0.0 else (orc.position.y - oorc.end.y))
		if abs(dy) >= abs(dx):
			if vb.end.x + MIN_GAP > ob.position.x and ob.end.x + MIN_GAP > vb.position.x:
				if dy >= 0.0:
					max_p.y = min(max_p.y, ob.position.y - gap_y)
				else:
					min_p.y = max(min_p.y, ob.end.y + gap_y)
		else:
			if vb.end.y + MIN_GAP > ob.position.y and ob.end.y + MIN_GAP > vb.position.y:
				if dx >= 0.0:
					max_p.x = min(max_p.x, ob.position.x - gap_x)
				else:
					min_p.x = max(min_p.x, ob.end.x + gap_x)
	if orc != null:
		if orc.position.x >= MIN_GAP:
			min_p.x = max(min_p.x, MIN_GAP)
		if orc.position.y >= MIN_GAP:
			min_p.y = max(min_p.y, MIN_GAP)
		if ctx.rect_size.x - orc.end.x >= MIN_GAP:
			max_p.x = min(max_p.x, ctx.rect_size.x - MIN_GAP)
		if ctx.rect_size.y - orc.end.y >= MIN_GAP:
			max_p.y = min(max_p.y, ctx.rect_size.y - MIN_GAP)
	var band = Rect2(min_p, max_p - min_p)
	if band.size.x < 16.0 or band.size.y < 16.0:
		return full
	return band

func _collect_sibling_bounds(ctx):
	var bounds = []
	for child in ctx.get_children():
		if child is Control and child.visible:
			bounds.append(_visual_bounds(child, ctx))
		else:
			bounds.append(Rect2())
	return bounds

func _position_in_band(node, band):
	var pos = node.rect_position
	var size = node.rect_size
	pos.x = clamp(pos.x, band.position.x, max(band.position.x, band.end.x - size.x))
	pos.y = clamp(pos.y, band.position.y, max(band.position.y, band.end.y - size.y))
	node.rect_position = pos

func _shrink_to_fit(child, band):
	var f0 = _base_min(child)
	_apply_scale(child, 1.0)
	var f1 = child.get_combined_minimum_size()
	var inc = f1 - f0
	if inc.x <= 0.5 and inc.y <= 0.5:
		return 1.0
	var s = 1.0
	if f1.x > band.size.x and inc.x > 0.5 and f0.x <= band.size.x:
		s = min(s, (band.size.x - f0.x) / inc.x)
	if f1.y > band.size.y and inc.y > 0.5 and f0.y <= band.size.y:
		s = min(s, (band.size.y - f0.y) / inc.y)
	s = clamp(s, 0.0, 1.0)
	if s < 0.999:
		_apply_scale(child, s)
	return s

func _apply_scale(node, s):
	if node is Control:
		var record = _originals.get(node.get_instance_id(), null)
		if record != null and record.get("active", false):
			if "mod_min" in record:
				node.rect_min_size = record.orig_min + (record.mod_min - record.orig_min) * s
			elif "mod_sep" in record:
				node.add_constant_override("separation", record.orig_sep + (record.mod_sep - record.orig_sep) * s)
	for child in node.get_children():
		_apply_scale(child, s)

func _force_sort(node):
	var id = node.get_instance_id()
	if id in _sorted_pass:
		return
	_sorted_pass[id] = true
	if node is Container:
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for child in node.get_children():
		_force_sort(child)

func _clamp_child_into_parent(child, parent):
	var pos = child.rect_position
	var size = child.rect_size
	pos.x = clamp(pos.x, 0.0, max(0.0, parent.rect_size.x - size.x))
	pos.y = clamp(pos.y, 0.0, max(0.0, parent.rect_size.y - size.y))
	child.rect_position = pos

func _clamp_position(node):
	var pos = node.rect_position
	var size = node.rect_size
	pos.x = clamp(pos.x, 0.0, max(0.0, VIEWPORT_W - size.x))
	pos.y = clamp(pos.y, 0.0, max(0.0, VIEWPORT_H - size.y))
	node.rect_position = pos

func _restore_all():
	for id in _originals:
		var record = _originals[id]
		if record.get("active", false):
			_restore_node(record)
			record.erase("active")

func _restore_node(record):
	var node = record.node.get_ref()
	if not node or not is_instance_valid(node):
		return
	if "orig_min" in record:
		node.rect_min_size = record.orig_min
	if "orig_size" in record:
		node.rect_size = record.orig_size
	if "orig_sep" in record:
		node.remove_constant_override("separation")
		if node.get_constant("separation") != record.orig_sep:
			node.add_constant_override("separation", record.orig_sep)
	if "orig_margin_left" in record:
		node.margin_left = record.orig_margin_left
		node.margin_top = record.orig_margin_top
		node.margin_right = record.orig_margin_right
		node.margin_bottom = record.orig_margin_bottom
		node.rect_clip_content = record.orig_clip

func _visual_bounds(node, ctx):
	var rects = []
	_collect_visual(node, ctx, rects)
	if rects.empty():
		return Rect2()
	var acc = rects[0]
	for i in range(1, rects.size()):
		var r = rects[i]
		var p = Vector2(min(acc.position.x, r.position.x), min(acc.position.y, r.position.y))
		var e = Vector2(max(acc.end.x, r.end.x), max(acc.end.y, r.end.y))
		acc = Rect2(p, e - p)
	return acc

func _collect_visual(node, ctx, rects):
	if not (node is Control):
		for child in node.get_children():
			_collect_visual(child, ctx, rects)
		return
	if not node.visible:
		return
	if node != ctx and _draws_self(node):
		rects.append(_to_root_rect(node, ctx))
	for child in node.get_children():
		_collect_visual(child, ctx, rects)

func _to_root_rect(node, ctx):
	var gp = node.rect_global_position - ctx.rect_global_position
	return Rect2(gp, node.rect_size)

func _draws_self(node):
	return node is Panel or node is PanelContainer or node is TextureRect or node is Label or node is BaseButton or node is LineEdit or node is ScrollContainer or node is ColorRect or node is RichTextLabel

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
#		var ev = InputEventKey.new()
#		ev.scancode = KEY_ESCAPE
#		ev.physical_scancode = KEY_ESCAPE
#		ev.pressed = true
#		Input.parse_input_event(ev)
		emit_signal("swiped_back")

func _input(event):
	pass
	if event is InputEventScreenTouch:
		if not _emulate_mouse_from_touch():
			if event.pressed:
				_begin_drag(event.position)
			else:
				_end_drag()
	elif event is InputEventScreenDrag:
		if not _emulate_mouse_from_touch():
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

func _emulate_mouse_from_touch():
	return ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch")

func _begin_drag(pos):
	var sc = _find_scroll_at(pos)
	if sc != null and _on_scrollbar(sc, pos):
		sc = null
	_drag_scroll = sc
	_drag_active = false
	_drag_start = pos
	_drag_last = pos

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
