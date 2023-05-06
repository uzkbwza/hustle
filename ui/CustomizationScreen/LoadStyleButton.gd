extends OptionButton

signal style_selected(style)

export var player_id = 1
export var save_style = false

var last_id = 0

var loaded_styles = []
var loaded_style_paths = []

func load_last_style():
	yield(get_tree(), "idle_frame")
	var last_style = Global.get_player_data()["last_style"]
	for i in range(loaded_style_paths.size()):
		if loaded_style_paths[i] == last_style:
			_on_LoadStyleButton_item_selected(i+1)

func update_styles():
	clear()
	loaded_styles.clear()
	loaded_style_paths.clear()
	add_item("load style")
	var styles_and_files = Custom.load_all_styles()
	var all_styles = styles_and_files[0]
	var all_style_paths = styles_and_files[1]
	var style_paths = []
	var styles = []
	for i in range (all_styles.size()):
		var style = all_styles[i]
		var style_path = all_style_paths[i]
		if Custom.can_use_style(player_id, style):
			styles.append(style)
			style_paths.append(style_path)

	for i in range(styles.size()):
		var style = styles[i]
		var style_path = all_style_paths[i]
		add_item(style.style_name, i)
		loaded_styles.append(style)
		loaded_style_paths.append(style_path)
	
func _on_LoadStyleButton_item_selected(index):
	if index > 0:
		if save_style:
			Global.save_player_data({"last_style": loaded_style_paths[index - 1]})
		emit_signal("style_selected", loaded_styles[index - 1])
	else:
		if save_style:
			Global.save_player_data({"last_style": ""})
		emit_signal("style_selected", null)

func _on_LoadStyleButton_pressed():
	last_id = selected
	update_styles()
	selected = last_id
