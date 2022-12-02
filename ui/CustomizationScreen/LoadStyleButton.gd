extends OptionButton

signal style_selected(style)

export var player_id = 1

var loaded_styles = []

func update_styles():
	clear()
	loaded_styles.clear()
	add_item("load style")
	var all_styles = Custom.load_all_styles()
	var styles = []
	for style in all_styles:
		if Custom.can_use_style(player_id, style):
			styles.append(style)
	for i in range(styles.size()):
		var style = styles[i]
		add_item(style.style_name, i)
		loaded_styles.append(style)

func _on_LoadStyleButton_item_selected(index):
	if index > 0:
		emit_signal("style_selected", loaded_styles[index - 1])
	else:
		emit_signal("style_selected", null)
