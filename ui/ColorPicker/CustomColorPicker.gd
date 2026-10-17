extends Panel

class_name YomiColorPicker

signal color_changed(color)

var current_color = Color.white
var current_hsv = {}

onready var color_spectrum = $"%ColorSpectrum"
onready var value_rect = $"%ValueRect"
onready var color_display = $"%ColorDisplay"
onready var picker_rect = $"%PickerRect"
onready var hex_edit = $"%HexEdit"
onready var revert_button = $"%RevertButton"

func _ready():
	revert_button.connect("pressed", self, "_on_revert_pressed")

func _on_revert_pressed():
	hex_edit.text = current_color.to_html(false)

func _process(_delta):
	color_display.color = color_spectrum.col
	if visible:
		if color_spectrum.mouse_pressed or color_spectrum.picked:
			picker_rect.show()
			picker_rect.rect_position = color_spectrum.rect_position + color_spectrum.mouse_pos - Vector2(2, 2)
		if color_spectrum.mouse_pressed:
			hex_edit.text = color_spectrum.col.to_html(false)
		if value_rect.mouse_pressed:
			color_spectrum.get_material().set_shader_param("value", value_rect.value)
			color_spectrum.value = value_rect.value
			color_spectrum.update_color()
			hex_edit.text = color_spectrum.col.to_html(false)
	color_display.color = color_spectrum.col
	if color_display.color != current_color:
		current_color = color_display.color
		# Skip the refresh while the user is typing in the box so we don't
		# overwrite a partial entry with the canonical hex of the parsed color.
		if not hex_edit.has_focus():
			hex_edit.text = current_color.to_html(false)
		emit_signal("color_changed", current_color)
	revert_button.disabled = hex_edit.text == current_color.to_html(false)

func set_color(col):
	color_spectrum.col = col
	color_spectrum.col.a = 1.0
	# Emit unconditionally — `_process` only emits on detected change, which
	# misses the case where set_color is called with the same color the picker
	# already has (e.g., loading a white style after a reset that nulled the
	# owner's cached color member). Forcing the emit guarantees listeners
	# overwrite their cached value to match the loaded style.
	current_color = col
	hex_edit.text = col.to_html(false)
	emit_signal("color_changed", current_color)

func _on_LineEdit_text_changed(new_text):
	picker_rect.hide()
	color_spectrum.picked = false
	color_spectrum.col = Color(new_text)
	color_spectrum.col.a = 1.0
