extends ScrollContainer

export var tab_name:String = "My Options"

var ModOptions

var default_schema:Dictionary = {}
var current_values:Dictionary = {}
var nodes:Dictionary = {}

var userdata := {}

var late_inited = false

var needs_to_save = false

const OPTION_TYPE_PATH := "res://SoupModOptions/OptionTypes/"

var option_types := {
	"Checkbutton": preload("res://SoupModOptions/OptionTypes/CheckbuttonOption.gd"),
	"Spinbox": preload("res://SoupModOptions/OptionTypes/SpinboxOption.gd"),
	"Slider": preload("res://SoupModOptions/OptionTypes/SliderOption.gd"),
	"String": preload("res://SoupModOptions/OptionTypes/StringOption.gd"),
	"OptionButton": preload("res://SoupModOptions/OptionTypes/OptionButtonOption.gd"),
	"Label": preload("res://SoupModOptions/OptionTypes/LabelOption.gd"),
	"Category": preload("res://SoupModOptions/OptionTypes/CategoryOption.gd"),
}

signal menu_opened
signal menu_closed
signal item_added
signal late_init

var tab_btn:Node
# Called when the node enters the scene tree for the first time.
func _ready():
	_generate_default_schema()
	current_values = default_schema.duplicate(true)
	sync_objects_to_values(nodes)
	_try_load()
	
	#connect post-init signal (for adding things to the schema)
	connect("item_added", self, "_option_added_post_init")
	
func show():
	.show()
	emit_signal("menu_opened")

func hide():
	.hide()
	emit_signal("menu_closed")

# Option Addition Funcs
func add_bool(internal_name, label, default:bool=false):
	var node = _create_generic(option_types.Checkbutton, internal_name, label, default)
	
	_add_to_list(internal_name, node)
	node.connect("option_changed", self, "option_changed")
	return node
	
func add_number_spinbox(internal_name, label, default = 0, optional_params := {}):
	var node = _create_generic(option_types.Spinbox, internal_name, label, default)
	
	_add_optional_params(node, optional_params)
	
	_add_to_list(internal_name, node)
	node.connect("option_changed", self, "option_changed")
	return node
	
	
func add_number_slider(internal_name, label, default = 0, optional_params := {}):
	var node = _create_generic(option_types.Slider, internal_name, label, default)
	
	_add_optional_params(node, optional_params)
	
	_add_to_list(internal_name, node)
	node.connect("option_changed", self, "option_changed")
	return node

func add_string_single(internal_name, label, default = ""):
	var node = _create_generic(option_types.String, internal_name, label, default)
	
	_add_to_list(internal_name, node)
	node.connect("option_changed", self, "option_changed")
	return node

func add_dropdown_menu(internal_name, label, default = 0):
	var node = _create_generic(option_types.OptionButton, internal_name, label, default)
	
	_add_to_list(internal_name, node)
	node.connect("option_changed", self, "option_changed")
	return node
	
func add_label(internal_name, label, align=Label.ALIGN_CENTER, color=Color.white):
	var node = _create_generic(option_types.Label, internal_name, label, label)
	node.align = align
	node.color = color
	
	_add_to_list(internal_name, node)
	return node

func add_category(internal_name, label, font_color=Color.white):
	var node = _create_generic(option_types.Category, internal_name, label, true)
	
	_add_to_list(internal_name, node)
	return node

# Internal Funcs
func _add_to_list(internal_name:String, node):
	var location_node = _resolve_slash_path(internal_name)
	location_node.add_child(node)
	emit_signal("item_added", internal_name, node)

func _create_generic(type, internal_name, display_name, default_value):
	var node = type.new()
	var path = NodePath(internal_name)
	node.fullpath = internal_name
	node.internal_name = path.get_name(path.get_name_count()-1)
	node.name = node.internal_name
	node.display_name = display_name
	node.default_value = default_value
	
	return node

func _option_added_post_init(internal_name, option):
	if option.ignore:
		return
	var path = internal_name#.rsplit("/", true, 1)[0]
	#print(ModOptions._slash_path_dict(default_schema, path))
	var schemadict = ModOptions._slash_path_dict(default_schema, path)
	ModOptions._slash_path_dict(default_schema, path)[option.name] = option.default_value
	var nodesdict = ModOptions._slash_path_dict(nodes, path)
	ModOptions._slash_path_dict(nodes, path)[option.name] = option
	_try_load(internal_name)

func _add_optional_params(node, params:={}):
	for key in params.keys():
		if key in node:
			node.set(key, params[key])
	
func option_changed(internal_name, value):
	var nodepath = NodePath(internal_name)
	var nodename = nodepath.get_name(nodepath.get_name_count()-1)
	ModOptions._slash_path_dict(current_values, internal_name)[nodename] = value
	needs_to_save = true
	
func _generate_default_schema(optionlist_node=$OptionList, path=""):
	for option in optionlist_node.get_children():
		if option.ignore:
			continue
		elif option is option_types.Category:
			var pref = "/" if path != "" else ""
			var success_path = path+pref+option.internal_name
			ModOptions._slash_path_dict(default_schema, success_path)[option.internal_name] = {}
			ModOptions._slash_path_dict(nodes, success_path)[option.internal_name] = {"self":option}
			
			_generate_default_schema(option.get_node("CategoryContainer/OptionsContainer/OptionList"), success_path)
			continue
		ModOptions._slash_path_dict(default_schema, option.fullpath)[option.name] = option.default_value
		ModOptions._slash_path_dict(nodes, option.fullpath)[option.name] = option
	print(name+" schema: "+String(default_schema))
	
	
func _resolve_slash_path(string:String):
	var fullstring := "OptionList/"+string
	var path_parts := fullstring.split("/")
	var current_path := ""
	for p in path_parts:
		if p == path_parts[path_parts.size()-1]:
			break
		var prefix = ("/" if p != path_parts[0] else "")
		var temp_path = current_path+prefix+p
		var node = get_node(temp_path)
		#print(node.get_children())
		if node == null:
			return null
		
		if node is option_types.Category:
			temp_path += "/CategoryContainer/OptionsContainer/OptionList"
		
		current_path = temp_path
	return get_node(current_path)

func _try_load(path=""):
	if path == "":
		ModOptions.load_settings(name)
	else:
		ModOptions.load_single_setting(name, path)
	needs_to_save = false

func set_option(internal_name:String, value):
	var nodepath = NodePath(internal_name)
	var nodename = nodepath.get_name(nodepath.get_name_count()-1)
	#print(ModOptions._slash_path_dict(nodes, internal_name))
	var node = ModOptions._slash_path_dict(nodes, internal_name)[nodename]
	node.set_value(value)

func refresh_values(dict=nodes, path=""):
	for key in dict.keys():
		var node = dict[key]
		var pref = "/" if path != "" else ""
		var success_path = path+pref+key
		if node is Dictionary:
			refresh_values(node, success_path)
		elif key == "self":
			continue
		else:
			ModOptions._slash_path_dict(current_values, success_path)[node.name] = node.current_value

func sync_objects_to_values(nodes, cur_path=""):
	for key in nodes.keys():
		var pref = "/" if cur_path != "" else ""
		var success_path = cur_path+pref+key
		if nodes[key] is Dictionary:
			sync_objects_to_values(nodes[key], success_path)
		elif key == "self":
			continue
		else:
			set_option(success_path, ModOptions._slash_path_dict(current_values, success_path)[key])
