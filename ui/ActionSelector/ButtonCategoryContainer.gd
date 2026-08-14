extends Control

class_name ButtonCategoryContainer

signal prediction_selected()

const BOX_SIZE = 52
const DEFAULT_HEIGHT = 60
# Buttons visible in the collapsed (non-hovered) state — bottom 3 rows of
# 3 cols each. Used to compute the overflow cutoff and to decide when to
# trigger overflow at all (>9 means there's at least one hidden row).
const VISIBLE_LIMIT = 9

onready var action_data_container = $"%ActionDataContainer"
onready var action_data_panel_container = $"%ActionDataPanelContainer"
onready var button_container = $"%ButtonContainer"
onready var initiative_label = $"%InitiativeLabel"
onready var guard_break_label = $"%GuardBreakLabel"

var label_text = ""
var selected_button_text = ""
var active_button = null

var mouse_over = false
var can_update = true

var game = null
var player_id = null

var category_int = -1
var shown_label_index = 0
var shown_labels = []

var prediction_type = null
var visibility_update = false
var fighter: Fighter = null

# Original add-order of buttons in this category. Used to compute slot
# assignment and to restore order in the GridContainer after reparenting
# buttons in/out of `hidden_buttons_node` for the overflow collapse state.
var category_buttons = []
# Off-screen, invisible holder for buttons that overflow the collapsed view.
# Reparenting them here removes them from the GridContainer's layout and
# from input dispatch entirely — the cleanest way to make them un-hoverable
# while keeping them alive for restore.
var hidden_buttons_node = null

func init(name):
	label_text = name
	$"%Label".text = label_text

#func _on_gui_input(event: InputEvent):
#	if event is InputEventMouseButton:
#		if event.pressed:
#			raise()
#	snap_to_boundaries()

func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	hidden_buttons_node = Control.new()
	hidden_buttons_node.name = "HiddenButtons"
	hidden_buttons_node.visible = false
	hidden_buttons_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hidden_buttons_node.rect_position = Vector2(-9999999, -9999999)
	add_child(hidden_buttons_node)
	Global.connect("mobile_ui_changed", self, "adjust_ui")
	adjust_ui(Global.mobile_ui)


func adjust_ui(is_mobile):
	if is_mobile:
		rect_min_size = Vector2(98, 76)
		$"%ButtonContainer".columns = 3 #should be 5
	else:
		rect_min_size = Vector2(52, 60)
		$"%ButtonContainer".columns = 3
	rect_size = rect_min_size
	


func _on_visibility_changed():
	if visible and !visibility_update:
		$"%ScrollContainer".rect_clip_content = true
		visibility_update = true
		pass

func _owns(btn, bc) -> bool:
	# True if `btn` still belongs to this category — i.e. not reparented out
	# by external code (e.g. continue_button moved to TurnButtons).
	var p = btn.get_parent()
	return p == bc or p == hidden_buttons_node

func any_buttons_visible():
	var bc = $"%ButtonContainer"
	for button in category_buttons:
		if !_owns(button, bc):
			continue
		if button.visible:
			return true
	return false

func get_num_available_moves():
	var bc = $"%ButtonContainer"
	var count = 0
	for button in category_buttons:
		if !_owns(button, bc):
			continue
		if button.visible:
			count += 1
	return count

func update_mouse_over():
		$"%ScrollContainer".rect_clip_content = true
		$"%ScrollContainer".rect_min_size.y = BOX_SIZE
		rect_size.y = DEFAULT_HEIGHT
		call_deferred("set_pos_y", 0)
		mouse_over = false
		can_update = false

		shown_labels = []
		$UpdateTimer.start()
		guard_break_label.hide()
		initiative_label.hide()
		

func update_mouse_elsewhere():
		$"%ScrollContainer".rect_clip_content = false
		# +1 to compensate for bc's margin_bottom=-1 (bc.bottom = SC.size - 1).
		# Otherwise bc.top would land at -1 in SC.local for overflow categories
		# on hover and clip the top row's first pixel. Also clamped to BOX_SIZE
		# so ≤9 categories don't pick up an unwanted positive set_pos_y offset.
		$"%ScrollContainer".rect_min_size.y = max($"%ButtonContainer".rect_size.y + 1, BOX_SIZE)
#		guard_break_label.hide()
		rect_size.y = 1000
		mouse_over = true
		can_update = false
		$UpdateTimer.start()
#		rect_position.y = -$"%ScrollContainer".rect_min_size.y + BOX_SIZE
		call_deferred("set_pos_y", -$"%ScrollContainer".rect_min_size.y + BOX_SIZE)
			
func _process(_delta):
#	if visible:
#		snap_to_boundaries()
#	if action_data_panel_container.visible and game:
#		snap_action_data_to_player()
#		action_data_panel_container.rect_global_position
#		pass

	if !mouse_over and can_update and Utils.is_mouse_in_control(self):
		update_mouse_elsewhere()

	elif mouse_over and can_update and !Utils.is_mouse_in_control(self) and !Utils.is_mouse_in_control($"%ButtonContainer"):
		update_mouse_over()

	update_button_layout()
	call_deferred("set_pos_y", -$"%ScrollContainer".rect_min_size.y + BOX_SIZE)
	$"VBoxContainer/CenterContainer".rect_position.y = 0
	$"%TooManyMoves".visible = get_num_available_moves() > 9
	if mouse_over:
		$"%TooManyMoves".visible = false
	set_deferred("visibility_update", false)
	
	guard_break_label.hide()
	initiative_label.hide()
	if shown_labels and (mouse_over):
		shown_labels[shown_label_index % len(shown_labels)].show()

func set_pos_y(y):
	rect_position.y = y

#func snap_action_data_to_player():
#	var screen_pos = game.get_screen_position(player_id)
#	var center_pos = get_viewport_rect().size/2 - action_data_panel_container.rect_size/2
#	action_data_panel_container.rect_global_position = screen_pos + center_pos
#	if active_button and active_button.data_node:
#		action_data_panel_container.rect_global_position += active_button.data_node.display_offset
#	action_data_panel_container.raise()

func enable_predict_button():
	$"%PredictButton".show()
#	$"%PredictButton".modulate.a = 1.0

func disable_predict_button():
#	$"%PredictButton".modulate.a = 0.25
	$"%PredictButton".hide()

func add_button(button):
	category_buttons.append(button)
	$"%ButtonContainer".add_child(button)
	button.connect("mouse_entered", self, "on_button_mouse_entered", [button])
	button.connect("mouse_exited", self, "on_button_mouse_exited")
	update_button_layout()

func update_button_layout():
	var bc = $"%ButtonContainer"
	var cols = bc.columns

	# Walk category_buttons (canonical order). Visible ones get a slot index
	# in the post-filler grid. The grid is anchored to the bottom and grows
	# upward, so the visible 52px window shows the BOTTOM 3 rows (last
	# VISIBLE_LIMIT slots). Anything in earlier rows belongs in
	# `hidden_buttons_node` while collapsed.
	# Skip buttons reparented externally (e.g. continue_button moved to
	# TurnButtons by ActionButtons.init) — their parent is neither bc nor
	# hidden_buttons_node, so we shouldn't yank them back.
	var visible_count = 0
	for btn in category_buttons:
		if !_owns(btn, bc):
			continue
		if btn.visible:
			visible_count += 1

	var hide_overflow = !mouse_over and visible_count > VISIBLE_LIMIT
	var hidden_count = (visible_count - VISIBLE_LIMIT) if hide_overflow else 0
	# Total grid slot count must stay constant across collapsed/hovered so the
	# bc rect doesn't change size between states (which would cause a vertical
	# pixel jump in the label/parent layout). For the visible_count-aligned
	# layout, we add `hidden_count` extra fillers when collapsed to replace
	# the buttons we reparented out — keeping bc.rect_size.y identical.
	var needed = 0
	if visible_count > VISIBLE_LIMIT:
		needed = (cols - (visible_count % cols)) % cols + hidden_count

	var visible_idx = 0
	for btn in category_buttons:
		if !_owns(btn, bc):
			continue
		var should_be_hidden = false
		if btn.visible:
			should_be_hidden = hide_overflow and visible_idx < hidden_count
			visible_idx += 1
		var current_parent = btn.get_parent()
		var target_parent = hidden_buttons_node if should_be_hidden else bc
		if current_parent != target_parent:
			current_parent.remove_child(btn)
			target_parent.add_child(btn)

	# Restore canonical order in the GridContainer: fillers first, then
	# category_buttons (the ones currently parented to bc) in add-order.
	var fillers = []
	for child in bc.get_children():
		if child.has_meta("is_filler"):
			fillers.append(child)
	var index = fillers.size()
	for btn in category_buttons:
		if btn.get_parent() == bc:
			bc.move_child(btn, index)
			index += 1

	if fillers.size() == needed:
		return

	while fillers.size() > needed:
		var f = fillers.pop_back()
		bc.remove_child(f)
		f.queue_free()

	while fillers.size() < needed:
		var f = Control.new()
		f.set_meta("is_filler", true)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Match ActionButton's min height so a row of pure fillers still takes
		# up a button-row's worth of vertical space — otherwise GridContainer
		# collapses the row to 0px (rows size to max child height) and
		# bc.rect_size.y differs between collapsed/hovered, causing the layout
		# to jump by a row when overflow buttons get reparented.
		f.rect_min_size = Vector2(0, 16)
		bc.add_child(f)
		fillers.append(f)

	for i in range(needed):
		bc.move_child(fillers[i], i)


func get_prediction():
	return $"%PredictButton".pressed and $"%PredictButton".visible

func reset_prediction():
	$"%PredictButton".set_pressed_no_signal(false)

func refresh():
	if get_prediction():
		$"%Label".text = label_text
		$"%Label".modulate = Color.white
		$"%Label".modulate.a = 1.0
		return
	guard_break_label.hide()
	initiative_label.hide()
	var initiative = fighter.check_initiative()
	var bc = $"%ButtonContainer"
	for button in category_buttons:
		if !_owns(button, bc):
			continue
		if button.is_pressed():
			on_button_mouse_entered(button)
			$"%Label".modulate = Color.cyan
			active_button = button
			selected_button_text = button.action_title
			update_frame_display(button)
			update_mouse_elsewhere()
			return
	$"%Label".text = label_text
	$"%Label".modulate = Color.white
	$"%Label".modulate.a = 0.25
	$"%FrameLabel".bbcode_text = ""
 
func update_labels(button):
	guard_break_label.hide()
	initiative_label.hide()
	shown_labels = []
	if button:
		if button.get("is_guard_break"):
			shown_labels.append(guard_break_label)
		if button.get("has_initiative_effect"):
			shown_labels.append(initiative_label)
	

func update_frame_display(button):
	$"%FrameLabel".bbcode_text = ""
	guard_break_label.hide()
	var bbcode = "[center]"
	var has_content = false
	if button and button.get("earliest_hitbox") and button.earliest_hitbox > 0:
		bbcode += "[color=#808080][~%sf][/color]" % button.earliest_hitbox
		has_content = true
	var super_level = _button_super_level(button)
	if super_level > 0:
		if has_content:
			bbcode += " "
		var color = "#00ffff"
		if super_level == 2:
			color = "#ff8000"
		elif super_level >= 3:
			color = "#ff00ff"
		bbcode += "[color=%s]lvl%d[/color]" % [color, super_level]
		has_content = true
	bbcode += "[/center]"
	if has_content:
		$"%FrameLabel".bbcode_text = bbcode
#	if button and button.get("is_guard_break"):
#		guard_break_label.visible = button.is_guard_break
	update_labels(button)
	pass

func _button_super_level(button) -> int:
	if !button or !button.state:
		return 0
	# CharState.super_level_ is the canonical field (default 0 = not a super).
	var sl_underscore = button.state.get("super_level_")
	if sl_underscore != null and sl_underscore > 0:
		return sl_underscore
	# SuperMove and RobotState use 'super_level' (no underscore). Only count
	# if it's actually flagged as a super to avoid false positives.
	var sl = button.state.get("super_level")
	if sl != null and sl > 0:
		if button.state is SuperMove:
			return sl
		if button.state.get("is_super") == true:
			return sl
	return 0

func on_button_mouse_entered(button):
	if get_prediction():
		return
	_on_ButtonContainer_mouse_entered()
	$"%Label".text = button.action_title
#	if button.action_title == selected_button_text:
#		return
	update_frame_display(button)
	$"%Label".modulate = Color.green

func on_button_mouse_exited():
	shown_labels = []
	refresh()
#	guard_break_label.hide()

func show_data_container():
	$"%ActionDataPanelContainer".show()
#	yield(get_tree(), "idle_frame")
#	action_data_container.rect_size.y = min(action_data_container.container.rect_size.y, 80)
#	action_data_container.rect_position = Vector2(0, -action_data_container.rect_position.y - 1)
	
func hide_data_container():
	$"%ActionDataPanelContainer".hide()
#
#func add_data_node(node):
#	action_data_container.add_child(node)

#func snap_to_boundaries():
#	var viewport_size = get_viewport_rect().size
#	if rect_global_position.x < 0:
#		rect_global_position.x = 0
#	if rect_global_position.y < 0:
#		rect_global_position.y = 0
#	if rect_global_position.x + rect_size.x > viewport_size.x:
#		rect_global_position.x = viewport_size.x - rect_size.x
#	if rect_global_position.y + rect_size.y > viewport_size.y:
#		rect_global_position.y = viewport_size.y - rect_size.y


func _on_ButtonContainer_mouse_entered():
	
#	$"%ScrollContainer".rect_clip_content = false
#	mouse_over = true
	pass # Replace with function body.

func _on_ButtonContainer_mouse_exited():
#	$"%ScrollContainer".rect_clip_content = true
#	mouse_over = false
	pass # Replace with function body.


func _on_PredictButton_mouse_entered():
	$"%PredictLabel".show()
	$"%PredictLabel".text = "P" + str((player_id % 2) + 1) + " Prediction"
	pass # Replace with function body.


func _on_PredictButton_mouse_exited():
	$"%PredictLabel".hide()
	pass # Replace with function body.


func _on_PredictButton_pressed():
	refresh()
	emit_signal("prediction_selected")
	pass # Replace with function body.


func _on_UpdateTimer_timeout():
	can_update = true
	pass # Replace with function body.

func _on_CycleTimer_timeout():
	shown_label_index += 1

