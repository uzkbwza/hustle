tool
extends Control

# signal data_changed()
signal mouse_input_event(event)

onready var parent = get_parent()

var flash = false

func set_flash(on):
	flash = on

func _input(event:InputEvent):
	if Engine.editor_hint: return
	
	if event is InputEventMouseButton:
		call_deferred("emit_signal", "mouse_input_event", event)

func _draw():
	var radius = parent.panel_radius
	var midpoint = parent.midpoint()

	var limit_center = parent.get_limit_center()
	var limit_range = parent.get_limit_range()
	
	var bg_color = Color.black
	bg_color.a = 0.85
	var bg_line_color = Color.white
	var limit_color = Color.red
	var limit_bg_color = limit_color
	limit_bg_color.r *= 1
	limit_bg_color.a *= 0.25
	var padding = 2
	var draw_min_length = parent.min_length > 0
	bg_color = bg_color if not flash else Color("141414")
	
	draw_circle(midpoint, radius, bg_color)
	
	if parent.snap and parent.snap_radius > 0.0:
		var snap_radius_color = Color.green
		snap_radius_color.a = 0.5
		draw_arc(midpoint, parent.snap_radius * radius, 0, TAU, 32, snap_radius_color)
	
	if parent.limit_angle:
		if parent.limit_symmetrical:
			draw_circle_arc_poly(midpoint, radius - padding, limit_center + limit_range / 2, PI + limit_center - limit_range / 2, limit_bg_color)
			draw_circle_arc_poly(midpoint, radius - padding, PI + limit_center + limit_range / 2, TAU + limit_center - limit_range / 2, limit_bg_color)
		else:
			draw_circle_arc_poly(midpoint, radius - padding, limit_center + limit_range / 2, TAU + limit_center - limit_range / 2, limit_bg_color)

	if not parent.always_max and parent.min_length > 0:
		if parent.limit_angle:
			draw_circle_arc_poly(midpoint, parent.min_length * radius, limit_center - limit_range / 2, limit_center + limit_range / 2, limit_bg_color)
			if parent.limit_symmetrical:
				draw_circle_arc_poly(midpoint, parent.min_length * radius, PI + limit_center - limit_range / 2, PI + limit_center + limit_range / 2, limit_bg_color)
		else:
			draw_circle(midpoint, parent.min_length * radius, limit_bg_color)

	bg_line_color.a = 0.65
	draw_arc(midpoint, radius - 2, 0, TAU, 64, bg_line_color, 1.0)
	bg_line_color.a = 0.25
	if parent.snap:
		var highlight_line_rate = parent.snap_angles / 4 if parent.snap_angles % 4 == 0 else 1
		var snap_offset = limit_center if parent.snap_align_to_limit_center and parent.limit_angle else 0
		for i in range(parent.snap_angles):
			if i % highlight_line_rate == 0:
				bg_line_color.a = 0.25
			else:
				bg_line_color.a = 0.125
			var snap_angle = (float(i) / parent.snap_angles) * TAU
			draw_bg_line(snap_angle + snap_offset, bg_line_color)

	if not parent.always_max and parent.min_length > 0:
		if parent.limit_angle:
			if parent.limit_symmetrical:
				draw_arc(midpoint, parent.min_length * radius, PI + limit_center - limit_range / 2, PI + limit_center + limit_range / 2, 32, limit_color)
			draw_arc(midpoint, parent.min_length * radius, limit_center - limit_range / 2, limit_center + limit_range / 2, 32, limit_color)
		else:
			draw_arc(midpoint, parent.min_length * radius, 0, TAU, 32, limit_color)
		
	if parent.limit_angle:
		if parent.limit_symmetrical:
			draw_bg_line(PI + limit_center - limit_range / 2, limit_color, true)
			draw_bg_line(PI + limit_center + limit_range / 2, limit_color, true)

		draw_bg_line(limit_center - limit_range / 2, limit_color, true)
		draw_bg_line(limit_center + limit_range / 2, limit_color, true)
		if not parent.always_max:
			draw_arc(midpoint, parent.min_length, limit_center - limit_range / 2, limit_center + limit_range / 2, 32, limit_color)

func draw_bg_line(angle, color, from_min_length = false, padding = 2):
	var radius = parent.panel_radius
	var midpoint = parent.midpoint()
	var min_length = 0 if parent.always_max else parent.min_length
	draw_line(midpoint + (Vector2.RIGHT.rotated(angle) * (radius * min_length) if from_min_length else Vector2()), midpoint + Vector2.RIGHT.rotated(angle) * (radius - padding), color, 1.0)
	
func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nbPoints = 32
	var pointsArc = PoolVector2Array()
	pointsArc.push_back(center)
	var colors = PoolColorArray([color])
	
	for i in range(nbPoints + 1):
		var anglePoint = angle_from + i * (angle_to - angle_from) / nbPoints
		pointsArc.push_back(center + Vector2(cos((anglePoint)), sin((anglePoint))) * radius)
	draw_polygon(pointsArc, colors)
	pass
