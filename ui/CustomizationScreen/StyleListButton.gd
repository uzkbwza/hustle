extends OptionButton

# Dropdown that lets a player pick which saved style LIST drives the match
# randomizer. Mirrors the shape of LoadStyleButton: update the items on
# demand, then report the selected list through a signal. The actual random
# style pick happens elsewhere (see get_style_for_match on CharacterDisplay).
#
# Lists are the ".ymhlist" files saved by FileManagerInterface under
# user://lists/custom (see CustomizationScreen). Each one holds a dict with
# {"active": [style_name,...], "inactive": [...]} — active names are the pool
# the randomizer draws from.

const STYLE_LIST_DIR := "user://lists/custom"

signal list_selected(list_data)

export var player_id = 1
export var save_style = false

var loaded_lists := []           # every list dict (name + data) from disk
var cur_list_data : Dictionary = {}   # currently selected list (empty = none)
var last_id = 0

func update_lists() -> void:
	var previous = cur_list_data.get("list_name", "")
	clear()
	loaded_lists.clear()
	add_item("Random: Off")
	var lists = FileManager.load_all_lists(STYLE_LIST_DIR)
	# Pin "default" to the top of the dropdown; keep the rest in relative order.
	for list in lists.duplicate():
		if list.get("list_name", "") == "default":
			lists.erase(list)
			lists.insert(0, list)
			break
	for list in lists:
		# _current_state is an internal marker for remembering the last
		# selection, not a real user list - never show or pick it.
		if list.get("list_name", "") == "_current_state":
			continue
		var lname = list.get("list_name", "default")
		add_item(lname)
		loaded_lists.append(list)

	# Re-select the previously selected list if it still exists.
	cur_list_data = {}
	for i in range(loaded_lists.size()):
		if loaded_lists[i].get("list_name", "") == previous:
			selected = i + 1
			cur_list_data = loaded_lists[i]
			break


func _on_StyleListButton_item_selected(index: int) -> void:
	if index <= 0:
		cur_list_data = {}
	else:
		var i = index - 1
		if i >= 0 and i < loaded_lists.size():
			cur_list_data = loaded_lists[i]
	emit_signal("list_selected", cur_list_data)


func _on_StyleListButton_pressed() -> void:
	last_id = selected
	update_lists()
	selected = last_id


# Loads a saved list's data by its list_name. Returns {} if not found.
static func load_list_by_name(list_name: String) -> Dictionary:
	var lists = FileManager.load_all_lists(STYLE_LIST_DIR)
	for list in lists:
		if list.get("list_name", "") == list_name:
			return list
	return {}

static func pick_from_list(list_data: Dictionary, player_id: int, seed_value: int):
	var active = list_data.get("active", [])
	if typeof(active) != TYPE_ARRAY or active.empty():
		return null

	var all = Custom.load_all_styles()
	var all_styles = all[0]
	var all_paths = all[1]
	var pool := []
	for i in range(all_styles.size()):
		var style = all_styles[i]
		var style_key = all_paths[i].get_file().get_basename()
		if active.has(style_key) and Custom.can_use_style(player_id, style):
			pool.append(style)
	if pool.empty():
		return null
	var rng = BetterRng.new()
	rng.seed = seed_value
	return pool[rng.randi_range(0, pool.size() - 1)]

func get_random_style(seed_value: int):
	if cur_list_data.empty():
		return null
	return pick_from_list(cur_list_data, player_id, seed_value)
