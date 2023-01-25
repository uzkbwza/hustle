tool

extends Control

signal pressed()
signal insert_before()
signal insert_after()
signal delete()

var keyframe = false

var host_command = null

func _ready():
#	Utils.pass_along_signal($"%Button", self, "pressed")
	$"%Button".connect("pressed", self, "_on_button_pressed")
	Utils.pass_signal_along($"%InsertBefore", self, "pressed", "insert_before")
	Utils.pass_signal_along($"%InsertAfter", self, "pressed", "insert_after")
	Utils.pass_signal_along($"%Delete", self, "pressed", "delete")

func _on_button_pressed():
#	if keyframe:
		emit_signal("pressed")

func set_frame(i):
	$"%Button".text = str(i + 1)
	if i <= 0:
		$"%InsertBefore".disabled = true
		$"%Delete".disabled = true
func set_image(texture):
	$"%TextureRect".texture = texture

func set_keyframe(on):
	keyframe = on
	if keyframe:
		$"%TextureRect".modulate.a = 1.0
		$"%Button".modulate.a = 1.0
#		$"%Button".disabled = false
	else:
		$"%Button".modulate.a = 0.5
		$"%TextureRect".modulate.a = 0.25
#		$"%Button".disabled = true
