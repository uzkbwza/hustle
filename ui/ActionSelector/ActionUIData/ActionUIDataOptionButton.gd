extends OptionButton

signal data_changed

func _ready():
	connect("item_selected", self, "_on_toggled")

func _on_toggled(item):
	emit_signal("data_changed")

func get_data():
	return {
		id = selected,
		name = items[selected]
	}
