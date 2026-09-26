extends Node

# This is the main script for Mod Options. This is what people should hook.
var menu

func _ready():
	name = "ModOptions"
#	var my_menu = generate_menu("modOptionsMenu", "Mod Options Menu")
#	my_menu.add_label("lbl1", "Mod Options Menu Test")
#
#	my_menu.add_category("test_category", "Test Category")
#	my_menu.add_category("test_category/test_category_2", "Test Nested Category")
#	my_menu.add_bool("test_category/test_category_2/test_option", "Test Option")
#	my_menu.add_bool("test_category/test_option_2", "Test Option 2")
#	my_menu.add_number_spinbox("test_category/test_option_spinbox", "Test Spinbox")
#	my_menu.add_number_slider("test_option_slider", "Test Slider", 30, {min_value=20,max_value=80})
#	my_menu.add_string_single("test_option_string", "Test Singleline String")
#
#	var dropdown = my_menu.add_dropdown_menu("test_option_dropdown", "Test Dropdown Menu")
#	dropdown.add_item("Item 0")
#	dropdown.add_separator()
#	dropdown.add_item("Item 1")
#	dropdown.add_item("Item 2")
#
#	my_menu.add_label("lbl2", "This is a test label.", Label.ALIGN_LEFT)
#	my_menu.add_label("lbl3", "I still have some more types to implement...", Label.ALIGN_LEFT, Color.slategray)
#	my_menu.add_category("dynamic_setting_test", "Characters")
#	add_menu(my_menu)
#	my_menu.connect("menu_opened", self, "_soup_menu_opened", [my_menu])

func _notification(what):
	if what == NOTIFICATION_READY:
		#this gets called after _ready() so i can run something after the menus are all loaded
		for cur_menu in menu.menus:
			var node = menu.menus[cur_menu]
			node.connect("menu_opened", self, "_"+node.name+"_opened", [node])
			node.connect("menu_closed", self, "_"+node.name+"_closed", [node])
			node.connect("late_init", self, "_"+node.name+"_late_init", [node]) # Runs when Main is ready.
			pass
		pass

func _soup_menu_opened(menu):
	if !("dynamic_set" in menu.userdata):
		menu.add_bool("dynamic_setting_test/test_setting_a", "Test Setting A")
		
		menu.userdata.dynamic_set = true
	
func generate_menu(internal_name, display_name):
	var container = load("res://SoupModOptions/ModOptionsScene.gd").new()
	container.ModOptions = self
	var vbox:VBoxContainer = VBoxContainer.new()
	container.add_child(vbox)
	container.name = internal_name
	container.tab_name = display_name
	vbox.name = "OptionList"
	vbox.size_flags_horizontal = 3
	vbox.set_theme_type_variation("OptionList")
	return container

func add_menu(menu_node):
	#print("adding menu to scene")
	menu.add_menu_from_node(menu_node)

func load_settings(internal_name):
	var node = menu.menus[internal_name]
	
	var file = File.new()
	var filepath = get_file_path(internal_name)
	var data
	var recreate:bool = false;
	if not file.file_exists(filepath):
		save_settings(internal_name)
	file.open(filepath, File.READ)
	var parse_res = JSON.parse(file.get_as_text())
	if not parse_res.error:
		if parse_res.result is Dictionary:
			data = parse_res.result
	else:
		print(parse_res.error_string)
	# something bad happened. recreate.
	if not data is Dictionary:
		var dir = Directory.new()
		dir.remove(filepath)
		save_settings(internal_name)
		data = node.default_schema.duplicate(true)
	var schema = node.default_schema
	_recursive_load_values(node, schema)
	_recursive_load_values(node, data)
	node.refresh_values()

func load_single_setting(internal_name, setting):
	var node = menu.menus[internal_name]
	
	var file = File.new()
	var filepath = get_file_path(internal_name)
	var data
	if not file.file_exists(filepath):
		return null
	file.open(filepath, File.READ)
	var parse_res = JSON.parse(file.get_as_text())
	if not parse_res.error:
		if parse_res.result is Dictionary:
			data = parse_res.result
	else:
		print(parse_res.error_string)
		return null
	
	
	var path = _slash_path_dict(data, setting)
	#print(path)
	if path != null:
		var nodepath = NodePath(setting)
		var nodename = nodepath.get_name(nodepath.get_name_count()-1)
		if nodename in path:
			node.set_option(setting, path[nodename])
	node.refresh_values()

func _recursive_load_values(main_node, dict, cur_path=""):
	for key in dict.keys():
		var obj = dict[key]
		var node = dict[key]
		var pref = "/" if cur_path != "" else ""
		var success_path = cur_path+pref+key
		if obj is Dictionary:
			_recursive_load_values(main_node, obj, success_path)
		elif key == "self":
			continue # skip self key
		else:
			var node_resolve = main_node._resolve_slash_path(success_path)
			if node_resolve != null and node_resolve.has_node(key):
				main_node.set_option(success_path, obj)
				#print(success_path+": "+String(obj))


func _slash_path_dict(dict:Dictionary, path:String):
	# Returns the highest valid dictionary in the hierarchy given in path
	var current_result = dict
	var sep = path.split("/")
	var i = 0
	if sep.size() > 1:
		for s in sep:
			if s in current_result:
				if current_result[s] is Dictionary:
					current_result = current_result[s]
				else:
					return current_result
			else:
				if i != sep.size()-1:
					return null
			i += 1
	return current_result

func save_settings(internal_name):
	var node = menu.menus[internal_name]
	node.refresh_values()
	node.needs_to_save = false
	
	var dir:Directory = Directory.new()
	dir.open("user://")
	var file:File = File.new()
	var filepath = get_file_path(internal_name)
	var existing_data
	
	var schema = node.default_schema
	if not dir.dir_exists("modoptions"):
		dir.make_dir("modoptions")
	if not file.file_exists(filepath):
		existing_data = schema.duplicate(true)
	else:
		file.open(filepath, File.READ)
		var parse_res = JSON.parse(file.get_as_text())
		if not parse_res.error:
			if parse_res.result is Dictionary:
				existing_data = parse_res.result
			else:
				print(parse_res.error_string)
		if not (existing_data is Dictionary):
			dir.remove(filepath)
			existing_data = schema.duplicate(true)
	
	var data = node.current_values
	#existing_data.merge(data, true)
	existing_data = dict_deep_merge(existing_data, data)
	file.open(filepath, File.WRITE)
	file.store_string(JSON.print(existing_data,"\t"))
	file.close()

func dict_deep_merge(dict1, dict2, duplicate=true):
	if duplicate:
		dict1 = dict1.duplicate(true)
		dict2 = dict2.duplicate(true)
	for key in dict2:
		if dict2[key] is Dictionary:
			if key in dict1:
				dict_deep_merge(dict1[key], dict2[key], false)
			#dict1[key] = dict2[key]
		else:
			dict1[key] = dict2[key]
	return dict1

func get_setting(internal_name, setting):
#	assert(internal_name in menu.menus, "Internal name for options page "+internal_name+" not found")
#	assert(setting in menu.menus[internal_name].current_values, "Internal name for setting "+setting+" not found")
	var values_dict = menu.menus[internal_name].current_values
	var nodepath = NodePath(setting)
	var nodename = nodepath.get_name(nodepath.get_name_count()-1)
	return _slash_path_dict(values_dict, setting)[nodename]

func get_file_path(internal_name):
	return "user://modoptions/"+sanitize_string(internal_name)+".json"

func sanitize_string(string):
	var regex = RegEx.new()
	regex.compile('([\\\\<>/.":?* ])')
	return regex.sub(string,"_",true)
