tool
extends TextureRect

signal limb_set(pos, dir)

# Texture-space (pixel) coordinates of the active limb on this sprite.
var active_pos = null
# Texture-space direction vector (unit length) of the active limb.
var active_dir = null
# All other limbs' positions for context, dict of limb_name -> {pos: Vector2, dir: Vector2}.
var other_limbs = {}

# Drag state
var dragging = false
var drag_start = Vector2()
var drag_current = Vector2()

func _ready():
	# Allow grab_focus() to work — TextureRect defaults to FOCUS_NONE.
	focus_mode = Control.FOCUS_ALL
	# Repaint markers when the canvas is resized so they track the letterboxed,
	# aspect-preserved texture instead of drifting off the sprite.
	connect("resized", self, "update")

func clear():
	active_pos = null
	active_dir = null
	dragging = false
	update()

func set_active(pos, dir):
	active_pos = pos
	active_dir = dir
	dragging = false
	update()

func set_others(limbs):
	other_limbs = limbs
	update()

func _draw():
	if !texture:
		return
	# Other limbs as faded markers.
	for name in other_limbs:
		var entry = other_limbs[name]
		var p = _tex_to_screen(entry.pos)
		draw_circle(p, 4, Color(0.2, 0.2, 0.2, 0.6))
		draw_circle(p, 3, Color(0.6, 0.6, 1.0, 0.6))
		if entry.has("dir") and entry.dir != Vector2():
			var d = (entry.dir * _tex_scale()).normalized()
			draw_line(p, p + d * 14, Color(0.6, 0.6, 1.0, 0.6), 1.5)
	# Active limb marker.
	var draw_pos = null
	var draw_dir = null
	if dragging:
		draw_pos = drag_start
		var diff = drag_current - drag_start
		if diff.length() > 1:
			draw_dir = diff.normalized()
	elif active_pos != null:
		draw_pos = _tex_to_screen(active_pos)
		if active_dir != null and active_dir != Vector2():
			# Project the texture-space direction through the (possibly
			# non-uniform) scale so it lies correctly on the squashed sprite.
			draw_dir = (active_dir * _tex_scale()).normalized()
	if draw_pos != null:
		draw_circle(draw_pos, 5, Color.black)
		draw_circle(draw_pos, 4, Color.red)
		if draw_dir != null:
			draw_line(draw_pos, draw_pos + draw_dir * 22, Color.black, 2.0)
			draw_line(draw_pos, draw_pos + draw_dir * 22, Color.yellow, 1.0)

# The TextureRect uses stretch_mode KEEP_ASPECT_CENTERED: the texture keeps its
# aspect ratio and is centered, giving a single uniform scale plus a letterbox
# offset. Returns [scale: float, offset: Vector2] mapping texture pixels to
# canvas-local pixels.
func _tex_transform() -> Array:
	if !texture:
		return [1.0, Vector2()]
	var ts = texture.get_size()
	if ts.x == 0 or ts.y == 0:
		return [1.0, Vector2()]
	var scale = min(rect_size.x / ts.x, rect_size.y / ts.y)
	var offset = (rect_size - ts * scale) * 0.5
	return [scale, offset]

# Uniform texture->screen scale as a Vector2 (equal components), for projecting
# direction vectors. Uniform, so it preserves angles.
func _tex_scale() -> Vector2:
	var s = _tex_transform()[0]
	return Vector2(s, s)

# Texture-space pixel -> canvas-local (screen) position.
func _tex_to_screen(tex_pos: Vector2) -> Vector2:
	var t = _tex_transform()
	return tex_pos * t[0] + t[1]

# Canvas-local (screen) position -> texture-space pixel.
func _screen_to_tex(screen_pos: Vector2) -> Vector2:
	var t = _tex_transform()
	return (screen_pos - t[1]) / t[0]

const SHIFT_SNAP_STEP = PI / 16  # τ/32 — 11.25° increments

func _snap_to_angle(diff: Vector2) -> Vector2:
	if diff.length() < 2:
		return diff
	var snapped_angle = round(diff.angle() / SHIFT_SNAP_STEP) * SHIFT_SNAP_STEP
	return Vector2.RIGHT.rotated(snapped_angle) * diff.length()

func _gui_input(event):
	if !texture:
		return
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			# Take focus so the LimbFinder's hotkeys (space, V) start working
			# after the user starts interacting with the canvas.
			grab_focus()
			dragging = true
			drag_start = event.position
			drag_current = event.position
			update()
		else:
			if !dragging:
				return
			dragging = false
			# Convert drag_start to texture-space position.
			var tex_pos = _screen_to_tex(drag_start)
			var tex_pos_floor = Vector2(floor(tex_pos.x), floor(tex_pos.y))
			# Derive the direction in TEXTURE space so the stored angle matches
			# the real (unsquashed) sprite used in-game, not the distorted view.
			var tex_diff = (event.position - drag_start) / _tex_scale()
			if event.shift:
				tex_diff = _snap_to_angle(tex_diff)
			var dir
			if tex_diff.length() < 0.5:
				dir = Vector2()
			else:
				dir = tex_diff.normalized()
			emit_signal("limb_set", tex_pos_floor, dir)
	elif event is InputEventMouseMotion and dragging:
		drag_current = event.position
		# Snap the visual feedback while the user is holding shift so they
		# can see the snapped direction before releasing. Snap in texture space,
		# then map back so the preview matches the stored value.
		if event.shift:
			var scale = _tex_scale()
			drag_current = drag_start + _snap_to_angle((drag_current - drag_start) / scale) * scale
		update()
