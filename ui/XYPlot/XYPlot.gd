tool
extends Container

class_name XYPlot

signal data_changed()
signal pos_data_changed(pos, change)

enum PanelType {
	Full,
	Half,
	Quarter
}

# base panel. the thing that flashes if you arent using DI
onready var panel = $PlotPanel
# the nub. what moves with your pointer
onready var nub = $PlotPanelNub

# self explanatory
onready var x_label = $XLabel
onready var y_label = $YLabel
onready var update_timer = $"%UpdateTimer"

################################################################################
########################### property list boilerplate ##########################
################################################################################

func _get_property_list():
	var properties = []
	
	properties.append({
		name = "normalize_display",
		type = TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT
	})
	
	properties.append({
		name = "panel_type",
		type = TYPE_INT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Full,Half,Quarter",
		usage = PROPERTY_USAGE_DEFAULT
	})
	
	properties.append({
		name = "bottom_half",
		type = TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT if panel_type != PanelType.Full else PROPERTY_USAGE_NO_INSTANCE_STATE
	})

	properties.append({
		name = "left_quarter",
		type = TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT if panel_type == PanelType.Quarter else PROPERTY_USAGE_NO_INSTANCE_STATE
	})
	
	properties.append({
		name = "always_max",
		type = TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT
	})
	
	properties.append({
		name = "min_length",
		type = TYPE_REAL,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0,1",
		usage = PROPERTY_USAGE_NO_INSTANCE_STATE if always_max else PROPERTY_USAGE_DEFAULT
	})
	
	
	properties.append({
		name = "Limit Angle",
		type = TYPE_NIL,
		hint_string = "limit_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})

	properties.append({
		name = "limit_angle",
		type = TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT
	})

	var usage_of_limit_cat = PROPERTY_USAGE_DEFAULT if limit_angle else PROPERTY_USAGE_NO_INSTANCE_STATE
	
	properties.append({
		name = "limit_range_degrees",
		type = TYPE_REAL,
		usage = usage_of_limit_cat,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "1,359"
	})
	
	properties.append({
		name = "limit_center_degrees",
		type = TYPE_REAL,
		usage = usage_of_limit_cat,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "-180,179"
	})
	
	properties.append({
		name = "limit_symmetrical",
		type = TYPE_BOOL,
		usage = usage_of_limit_cat
	})
	
	properties.append({
		name = "default_value",
		type = TYPE_VECTOR2,
		usage = PROPERTY_USAGE_DEFAULT
	})
	
	properties.append({
		name = "Snap",
		type = TYPE_NIL,
		hint_string = "snap_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	properties.append({
		name = "snap",
		type = TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT,
	})

	var usage_of_snap_cat = PROPERTY_USAGE_DEFAULT if snap else PROPERTY_USAGE_NO_INSTANCE_STATE

	properties.append({
		name = "snap_angles",
		type = TYPE_REAL,
		usage = usage_of_snap_cat,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0,16"
	})

	properties.append({
		name = "snap_align_to_limit_center",
		type = TYPE_BOOL,
		usage = usage_of_snap_cat
	})
	
	properties.append({
		name = "snap_radius",
		type = TYPE_REAL,
		usage = usage_of_snap_cat,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0,1"
	})
	
	return properties

const PROPERTY_DEFAULTS = {
	"normalize_display": true,
	"panel_type": PanelType.Full,
	"bottom_half": false,
	"left_quarter": false,
	"always_max": false,
	"min_length": 0.0,
	"snap": true,
	"snap_angles": 8,
	"snap_align_to_limit_center": true,
	"snap_radius": 0.0,
	"limit_angle": false,
	"limit_range_degrees": 90.0,
	"limit_center_degrees": 0.0,
	"limit_symmetrical": false,
	"default_value": Vector2(0, 0)
}

func property_can_revert(property:String) -> bool:
	return property in PROPERTY_DEFAULTS

func property_get_revert(property:String):
	return PROPERTY_DEFAULTS.get(property)

################################################################################
############################# property setter hooks ############################
################################################################################

var panel_type = PanelType.Full setget set_panel_type
var always_max = false setget set_always_max
var snap = true setget set_snap
var limit_angle = false setget set_limit_angle
var normalize_display = true setget set_normalize_display
var left_quarter = false setget set_left_quarter
var bottom_half = false setget set_bottom_half
var min_length = 0.0 setget set_min_length
var limit_range_degrees = 90.0 setget set_limit_range_degrees
var limit_center_degrees = 0.0 setget set_limit_center_degrees
var limit_symmetrical = false setget set_limit_symmetrical
var snap_angles = 8 setget set_snap_angles
var snap_align_to_limit_center = true setget set_snap_align_to_limit_center
var snap_radius = 0.0 setget set_snap_radius
var default_value = Vector2(0, 0) setget set_default_value

# note that any use of `update_value` here is meant to refresh the position of
#  the nub for editor purposes

# these properties change the visibility of other properties

func set_panel_type(val):
	panel_type = val

	plot_panel_size = get_panel_size()
	plot_panel_padding = get_panel_padding()

	if panel_type == PanelType.Quarter:
		panel_radius = plot_panel_size.x
	else:
		panel_radius = plot_panel_size.x / 2
	
	rect_min_size = plot_panel_size + (plot_panel_padding * 2) + PLOT_PANEL_BASE_PADDING
	set_size(plot_panel_size + (plot_panel_padding * 2) + PLOT_PANEL_BASE_PADDING)
	
	if Engine.editor_hint:
		update_value(get_default_value())
		property_list_changed_notify()
		update()

func set_always_max(val):
	always_max = val
	if Engine.editor_hint:
		update_value(get_default_value())
		property_list_changed_notify()
		update()
		
func set_snap(val):
	snap = val
	if Engine.editor_hint:
		update_value(get_default_value())
		property_list_changed_notify()
		update()
		
func set_limit_angle(val):
	limit_angle = val
	if Engine.editor_hint:
		update_value(get_default_value())
		property_list_changed_notify()
		update()

# these do not

func set_normalize_display(val):
	normalize_display = val
	if Engine.editor_hint:
		update_value(get_default_value())
		update()
		
func set_left_quarter(val):
	left_quarter = val
	if Engine.editor_hint:
		update_value(get_default_value())
		update()
		
func set_bottom_half(val):
	bottom_half = val
	if Engine.editor_hint:
		update_value(get_default_value())
		update()
		
func set_min_length(val):
	if Engine.editor_hint:
		min_length = round(val * 20) / 20
		update_value(get_default_value())
		update()
	else:
		min_length = val
		
func set_limit_range_degrees(val):
	if Engine.editor_hint:
		limit_range_degrees = round(val)
		update_value(get_default_value())
		update()
	else:
		limit_range_degrees = val
		
func set_limit_center_degrees(val):
	if Engine.editor_hint:
		limit_center_degrees = round(val)
		update_value(get_default_value())
		update()
	else:
		limit_center_degrees = val
		
func set_limit_symmetrical(val):
	limit_symmetrical = val
	if Engine.editor_hint:
		update_value(get_default_value())
		update()
		
func set_snap_angles(val):
	snap_angles = int(val)
	if Engine.editor_hint:
		update_value(get_default_value())
		update()
		
func set_snap_align_to_limit_center(val):
	snap_align_to_limit_center = val
	if Engine.editor_hint:
		update_value(get_default_value())
		update()
		
func set_snap_radius(val):
	if Engine.editor_hint:
		snap_radius = round(val * 100) / 100
		update_value(get_default_value())
		update()
	else:
		snap_radius = val
		
func set_default_value(val):
	default_value = val
	if Engine.editor_hint:
		update_value(get_default_value())
		update()
	else:
		update_value(get_default_value(), false)






















































func _ready():
	$Label.text = name

	if not Engine.editor_hint:
		panel.connect("mouse_entered", self, "_on_plot_mouse_entered")
		panel.connect("mouse_exited", self, "_on_plot_mouse_exited")
		panel.connect("mouse_input_event", self, "_on_plot_mouse_input_event")

	$UpdateTimer.connect("timeout", self, "_on_update_timer_timeout")

	panel.parent = self
	
	default_value = get_default_value()
	update_value(default_value, false)

func _process(_delta):
	if Engine.editor_hint: return
	if not visible: return
	
	if mouse_over and mouse_clicked:
		update_value()

	if buffer_changed:
		buffer_changed = false
		if is_visible_in_tree():
			call_deferred("emit_signal", "data_changed")

	var rect = get_global_rect()
	var mouse_position = get_global_mouse_position()
	if (not rect.has_point(mouse_position)):
		if not get_parent().visible:
			mouse_clicked = false
			mouse_over = false
	
func update():
	if panel:
		panel.update()
	if nub:
		nub.update()
	.update()

################################################################################
################################ container logic ###############################
################################################################################

var plot_panel_size = Vector2(50, 50)
var plot_panel_padding = Vector2(0, 0)

const TOP_LABEL_SIZE = 11
const BOTTOM_LABEL_SIZE = 11

const LABEL_NEGATIVE_PADDING = 3

const PLOT_PANEL_BASE_PADDING = Vector2(10, TOP_LABEL_SIZE+BOTTOM_LABEL_SIZE-(LABEL_NEGATIVE_PADDING*2))

const FULL_CIRCLE_SIZE = Vector2(50, 50)
const HALF_CIRCLE_SIZE = Vector2(80, 40)
const QUARTER_CIRCLE_SIZE = Vector2(45, 45)

const FULL_CIRCLE_PADDING = Vector2(0, 0)
const HALF_CIRCLE_PADDING = Vector2(0, 5)
const QUARTER_CIRCLE_PADDING = Vector2(2.5, 2.5)

func _rect_for(child):
	match child.name:
		"PlotPanel", "PlotPanelNub":
			return Rect2(
				Vector2(plot_panel_padding.x, plot_panel_padding.y+TOP_LABEL_SIZE-LABEL_NEGATIVE_PADDING),
				plot_panel_size
			)
		"Label":
			return Rect2(
				Vector2(0, 0),
				Vector2(plot_panel_size.x + (plot_panel_padding.x * 2), child.rect_min_size.y)
			)
		"XLabel":
			return Rect2(
				Vector2(plot_panel_size.x + (plot_panel_padding.x * 2), TOP_LABEL_SIZE-LABEL_NEGATIVE_PADDING),
				Vector2(35, plot_panel_size.y + plot_panel_padding.y * 2)
			)
		"YLabel":
			return Rect2(
				Vector2(0, (plot_panel_padding.y * 2) + plot_panel_size.y+TOP_LABEL_SIZE-(LABEL_NEGATIVE_PADDING*2)),
				Vector2(plot_panel_size.x + plot_panel_padding.x * 2, child.rect_min_size.y)
			)
		_:
			return Rect2()

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		for c in get_children():
			if not c is Timer:
				fit_child_in_rect(c, _rect_for(c))

################################################################################
################################## panel logic #################################
################################################################################

var mouse_over = false
var mouse_clicked = false
var buffer_changed = false
var buffer_update = false

const PERCENT_MAX = 100

var value_float = Vector2()

const SNAP_AMOUNT = 0.1

func _on_update_timer_timeout():
	if mouse_clicked and mouse_over:
		emit_signal("data_changed")
		update_timer.start(get_update_speed())

func _on_plot_mouse_entered():
	mouse_over = true
	x_label.show()
	y_label.show()

func _on_plot_mouse_exited():
	mouse_over = false
	if not mouse_clicked:
		x_label.hide()
		y_label.hide()

func get_update_speed():
	return ((1.0 + (1.0 / Global.get_ghost_speed_modifier())) / 2.0) * 0.3
	pass

func _on_plot_mouse_input_event(event:InputEventMouseButton):
	if event.button_index == BUTTON_LEFT:
		if event.pressed:
			if mouse_over:
				mouse_clicked = true
				update_timer.start(get_update_speed())
				call_deferred("emit_signal", "data_changed")
		else:
			mouse_clicked = false
			if buffer_update:
				buffer_changed = true
				buffer_update = false
	if event.button_index == BUTTON_RIGHT:
		if event.pressed:
			if mouse_over:
				update_value(get_default_value())
				call_deferred("emit_signal", "data_changed")

var panel_radius = plot_panel_size.x

func midpoint():
	var pos_y
	if panel_type != PanelType.Full:
		pos_y = 1 if bottom_half else plot_panel_size.y - 1
	else:
		pos_y = round(plot_panel_size.y / 2)

	var pos_x
	if panel_type == PanelType.Quarter:
		pos_x = plot_panel_size.x if left_quarter == (facing > 0) else 1
	else:
		pos_x = round(plot_panel_size.x / 2)
	
	return Vector2(pos_x, pos_y)

func update_value(p = null, set_buffer_update = true):
	var limit_center = get_limit_center()
	var limit_range = get_limit_range()

	var midpoint = midpoint()

	if set_buffer_update:
		buffer_update = true
	
	var point
	if p == null:
		var mpos = panel.get_local_mouse_position()
		point = (mpos - midpoint).limit_length(panel_radius)
	else :
		point = p
	if point == Vector2():
		if always_max or min_length > 0:
			if limit_angle:
				point = Utils.ang2vec(limit_center) * Vector2(facing, 1)
			else :
				point = Vector2.UP

	var angle = point.angle()
	if limit_angle:
		var diff = Utils.angle_diff(angle, limit_center)
		var closest = diff
		var diff2
		if limit_symmetrical:
			diff2 = Utils.angle_diff(angle, limit_center + PI)
			closest = diff if abs(diff) < abs(diff2) else diff2
		
		if abs(closest) > limit_range / 2:
			var length = point.length()
			var center = Utils.ang2vec(limit_center)
			var ang_diff = Utils.angle_diff(angle, limit_center)
			
			point = center.rotated((limit_range / 2) * - sign(ang_diff))
			point = point.normalized() * length
			angle = point.angle()
	
	if snap:
		if snap_radius > 0.0:
			if abs(point.length() / panel_radius - snap_radius) < SNAP_AMOUNT:
				point = point.normalized() * snap_radius * panel_radius
		
		if snap_angles > 0:
			var snap_offset = limit_center if snap_align_to_limit_center and limit_angle else 0
			for i in range(snap_angles):
				var snap_angle = snap_offset + ((float(i) / snap_angles) * TAU)
				var angle_diff = Utils.angle_diff(angle, snap_angle)
				if abs(angle_diff) < SNAP_AMOUNT:
					point = Utils.ang2vec(snap_angle) * point.length()
		
	if always_max:
		point = point.normalized() * panel_radius
	elif point.length() < min_length * panel_radius:
		point = point.normalized() * (min_length * panel_radius)

	value_float = point
	
	var pct_values = as_percentage_int_vec(value_float)

	if x_label:
		if normalize_display:
			x_label.text = str(pct_values.x / float(PERCENT_MAX))
			y_label.text = str(pct_values.y / float(PERCENT_MAX))
		else:
			x_label.text = str(pct_values.x)
			y_label.text = str(pct_values.y)
	
	var pos = midpoint + Vector2(
		(pct_values.x / float(PERCENT_MAX)) * panel_radius,
		(pct_values.y / float(PERCENT_MAX)) * panel_radius
	).round()
	if nub:
		nub.update_pos(pos)
	update()

func get_panel_size():
	match panel_type:
		PanelType.Full: return FULL_CIRCLE_SIZE
		PanelType.Half: return HALF_CIRCLE_SIZE
		PanelType.Quarter: return QUARTER_CIRCLE_SIZE

func get_panel_padding():
	match panel_type:
		PanelType.Full: return FULL_CIRCLE_PADDING
		PanelType.Half: return HALF_CIRCLE_PADDING
		PanelType.Quarter: return QUARTER_CIRCLE_PADDING

################################################################################
############################## setters and getters #############################
################################################################################

func set_flash(on):
	panel.set_flash(on)
	update()

func reset():
	update_value(get_default_value())

var facing = 1 setget set_facing
func set_facing(val):
	var old_facing = facing
	facing = val
	if facing != old_facing:
		update_value(value_float * Vector2(-1, 1))

func set_label(text):
	$"%Label".text = text

func get_limit_vec():
	return Utils.ang2vec(deg2rad(limit_center_degrees)) * Vector2(facing, 1)

func get_limit_center():
	return get_limit_vec().angle()

func get_limit_range():
	return deg2rad(limit_range_degrees)

################################################################################
############################### misc data + value ##############################
################################################################################


func get_default_value():
	var d = default_value
	if (always_max or min_length > 0) and d == Vector2():
		if limit_angle:
			d = Utils.ang2vec(get_limit_center()) * Vector2(facing, 1)
		else:
			d = Vector2.UP
	else:
		d.x *= facing
	return d.normalized()


func get_data():
	return as_percentage_int_vec(value_float)


func set_value_float(value):
	update_value(value)

func as_percentage_int_vec(vec2: Vector2):
	return {
		"x":int(round((vec2.x / panel_radius) * PERCENT_MAX)), 
		"y":int(round((vec2.y / panel_radius) * PERCENT_MAX)), 
	}

func get_value_float():
	return value_float
