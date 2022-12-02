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

func _process(_delta):
	color_display.color = color_spectrum.col
	if visible:
		if color_spectrum.mouse_entered and color_spectrum.mouse_pressed:
			picker_rect.show()
			picker_rect.rect_position = color_spectrum.rect_position + color_spectrum.mouse_pos - Vector2(2, 2)
			hex_edit.text = color_spectrum.col.to_html(false)
		if value_rect.mouse_entered and value_rect.mouse_pressed:
			color_spectrum.get_material().set_shader_param("value", value_rect.value)
			color_spectrum.value = value_rect.value
			color_spectrum.update_color()
			hex_edit.text = color_spectrum.col.to_html(false)
	color_display.color = color_spectrum.col
	if color_display.color != current_color:
		current_color = color_display.color
		emit_signal("color_changed", current_color)

func set_color(col):
	color_spectrum.col = col
	color_spectrum.col.a = 1.0

func _on_LineEdit_text_changed(new_text):
	picker_rect.hide()
	color_spectrum.col = Color(new_text)
	color_spectrum.col.a = 1.0
