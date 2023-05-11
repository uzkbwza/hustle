extends CheckButton

signal data_changed

func _ready():
	connect("toggled", self, "_on_toggled")

func _on_toggled(_on):
	emit_signal("data_changed")

func get_data():
	return pressed
