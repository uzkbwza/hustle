extends OptionButton

signal style_selected(style)

var loaded_styles = []

func update_styles():
	clear()
	loaded_styles.clear()
	add_item("load style")
	var styles = Custom.load_all_styles()
	for i in range(styles.size()):
		var style = styles[i]
		add_item(style.style_name, i)
		loaded_styles.append(style)

func _on_LoadStyleButton_item_selected(index):
	if index > 0:
		emit_signal("style_selected", loaded_styles[index - 1])
	else:
		emit_signal("style_selected", null)
