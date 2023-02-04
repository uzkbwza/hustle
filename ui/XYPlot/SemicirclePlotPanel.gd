extends Control

const SNAP_AMOUNT = 0.1

signal data_changed()

export var semicircle = false

var mouse_over = false
var mouse_clicked = false
var parent
var mpos = Vector2()

var x_value_float = 0.0
var y_value_float = 0.0

var buffer_update = false
var buffer_changed = false

var flash = false


func set_flash(on):
	flash = on

func init():
	call_deferred("update_value", parent.get_default_value())
	emit_signal("data_changed")

func _ready():
	rect_size.y = rect_size.x
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	x_value_float = 0
	y_value_float = 0
	call_deferred("update_value", Vector2())

func midpoint():
	return Vector2(rect_size.x / 2, rect_size.y)

func _on_mouse_entered():
	mouse_over = true
	pass

func _on_mouse_exited():
	mouse_over = false
	mouse_clicked = false
	pass

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				mouse_clicked = true
			else:
				mouse_clicked = false
				if buffer_update:
					buffer_changed = true
					buffer_update = false
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if mouse_over:
					update_value(Vector2())


func mouse_in_bounds():
	return !(mpos.x < 0 or mpos.x > rect_size.x or mpos.y < 0 or mpos.y > rect_size.y)

func update_value(p=null):
	buffer_update = true
	mpos = get_local_mouse_position()
	var point
	if p == null:
		point = (mpos - midpoint()).limit_length(rect_size.x / 2)
	else:
		point = p
	if point == Vector2():
		if parent.always_max or parent.min_length > 0:
			if parent.limit_angle:
				point = Utils.ang2vec(parent.limit_center)
			else:
				point = Vector2.UP

	var previous_vec = Vector2(x_value_float, y_value_float)
	var angle = point.angle()
	if parent.limit_angle:
		var diff = Utils.angle_diff(angle, parent.limit_center)
		var closest = diff
		var diff2
		if parent.limit_symmetrical:
			diff2 = Utils.angle_diff(angle, parent.limit_center + PI)
			closest = diff if abs(diff) < abs(diff2) else diff2

		if abs(closest) > parent.limit_range / 2:
			var real_point = point
			point = point.rotated(closest).rotated((parent.limit_range / 2) * Utils.int_sign(-closest))
			angle = point.angle()
			point = point.normalized() * point.length()
	
	if parent.snap:
		if point.length() >= (rect_size.x / 2) - SNAP_AMOUNT * (rect_size.x / 2):
			point = point.normalized() * (rect_size.x / 2)
		
		for i in range(8):
			var snap_angle = (TAU / 8) * i
			var angle_diff = Utils.angle_diff(angle, snap_angle)
			if abs(angle_diff) < SNAP_AMOUNT:
				point = Utils.ang2vec(snap_angle) * point.length()
		
		if parent.limit_angle:
			var snap_angle = parent.limit_center
			var angle_diff = Utils.angle_diff(angle, snap_angle)
			if abs(angle_diff) < SNAP_AMOUNT:
				point = Utils.ang2vec(snap_angle) * point.length()
	
	if parent.always_max:
		point = point.normalized() * (rect_size.x / 2)
	elif point.length() < parent.min_length * (rect_size.x / 2):
		point = point.normalized() * (parent.min_length * (rect_size.x / 2))

	x_value_float = point.x
	y_value_float = point.y
	
	var values = get_value()
	$"%XLabel".text = str(values.x) if !parent.normalize_display else str(values.x / float(parent.range_))
	$"%YLabel".text = str(values.y) if !parent.normalize_display else str(values.y / float(parent.range_))
	update()

func _process(_delta):
	if mouse_over and mouse_clicked:
		update_value()
	if buffer_changed:
		buffer_changed = false
		call_deferred("emit_signal", "data_changed")
	update()

func get_value():
	var values = {
		"x": int(round((x_value_float / (rect_size.x / 2)) * parent.range_)),
		"y": int(round((y_value_float / (rect_size.x / 2)) * parent.range_)),
	}
	return values

func _draw():
	var midpoint = midpoint()
	var values = get_value()
	var pos = midpoint + Vector2((values.x / float(parent.range_)) * rect_size.x / 2, (values.y / float(parent.range_)) * rect_size.y / 2).round()
	var bg_color = Color.black
	bg_color.a = 0.85
	var bg_line_color = Color.white
	var limit_color = Color.red
	var limit_bg_color = limit_color
	limit_bg_color.r *= 1
	limit_bg_color.a *= 0.25
	var padding = 2
	var draw_min_length = parent.min_length > 0
	draw_arc(midpoint, midpoint.x, PI, TAU, 32, bg_color)
	bg_color = bg_color if !flash else Color("333333")

	if parent.snap_radius > 0.0:
		var snap_radius_color = Color.green
		snap_radius_color.a = 0.5
		draw_arc(midpoint, parent.snap_radius * (rect_size.x / 2), 0, TAU, 32, snap_radius_color)
	
	if parent.limit_angle:

		if !parent.limit_symmetrical:
			draw_circle_arc_poly(midpoint, rect_size.x / 2 - padding, parent.limit_center + parent.limit_range / 2, TAU + parent.limit_center - parent.limit_range / 2, limit_bg_color)
		else:
			draw_circle_arc_poly(midpoint, rect_size.x / 2 - padding, parent.limit_center + parent.limit_range / 2, PI + parent.limit_center - parent.limit_range / 2, limit_bg_color)
			draw_circle_arc_poly(midpoint, rect_size.x / 2 - padding, PI + parent.limit_center + parent.limit_range / 2, TAU + parent.limit_center - parent.limit_range / 2, limit_bg_color)

#			draw_circle_arc_poly(midpoint, rect_size.x / 2 - padding, parent.limit_center + parent.limit_range / 2, -parent.limit_center - parent.limit_range / 2, Color.red)

	if parent.min_length > 0:
		draw_circle(midpoint, parent.min_length * (rect_size.x / 2), limit_bg_color)
		
	bg_line_color.a = 0.65
	draw_arc(midpoint, rect_size.x / 2 - 2, 0, TAU, 64, bg_line_color, 1.0)
	bg_line_color.a = 0.15
	draw_bg_line(deg2rad(45), bg_line_color)
	draw_bg_line(deg2rad(135), bg_line_color)
	draw_bg_line(deg2rad(225), bg_line_color)
	draw_bg_line(deg2rad(315), bg_line_color)
	bg_line_color.a = 0.25
	draw_bg_line(deg2rad(0), bg_line_color)
	draw_bg_line(deg2rad(90), bg_line_color)
	draw_bg_line(deg2rad(180), bg_line_color)
	draw_bg_line(deg2rad(270), bg_line_color)



	if parent.min_length > 0:
		draw_arc(midpoint, parent.min_length * (rect_size.x / 2), parent.limit_center - parent.limit_range / 2, parent.limit_center + parent.limit_range / 2, 32, limit_color)
		
	if parent.limit_angle:
		if parent.limit_symmetrical:
			draw_bg_line(PI + parent.limit_center - parent.limit_range / 2, limit_color, true)
			draw_bg_line(PI + parent.limit_center + parent.limit_range / 2, limit_color, true)

		draw_bg_line(parent.limit_center - parent.limit_range / 2, limit_color, true)
		draw_bg_line(parent.limit_center + parent.limit_range / 2, limit_color, true)
		draw_arc(midpoint, parent.min_length, parent.limit_center - parent.limit_range / 2, parent.limit_center + parent.limit_range / 2, 32, limit_color)


#	draw_line(Vector2(midpoint.x, padding), Vector2(midpoint.x, rect_size.y - padding), bg_line_color, 1.0)
	draw_line(midpoint, pos, Color.white, 1.0)
	draw_circle(pos, 3, Color.white)
	
func draw_bg_line(angle, color, from_min_length=false, padding=2):
	var midpoint = midpoint()
	draw_line(midpoint + (Vector2.RIGHT.rotated(angle) * (rect_size / 2 * parent.min_length) if from_min_length else Vector2()), midpoint + Vector2.RIGHT.rotated(angle) * (rect_size.x / 2 - padding), color, 1.0)
	
func draw_circle_arc_poly( center, radius, angle_from, angle_to, color ):
	var nbPoints = 32
	var pointsArc = PoolVector2Array()
	pointsArc.push_back(center)
	var colors = PoolColorArray([color])
	
	for i in range(nbPoints+1):
		var anglePoint = angle_from + i*(angle_to-angle_from)/nbPoints
		pointsArc.push_back(center + Vector2( cos( (anglePoint) ), sin( (anglePoint) ) )* radius)
	draw_polygon(pointsArc, colors)
	pass
