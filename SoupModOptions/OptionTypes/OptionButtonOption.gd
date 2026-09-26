extends "res://SoupModOptions/OptionTypes/ModOptionObject.gd"

var optionbutton:OptionButton
var label:Label
var options := []
var inited = false

signal item_added

func _build():
	var hsep := HBoxContainer.new()
	optionbutton = OptionButton.new()
	label = Label.new()
	hsep.add_child(label)
	hsep.add_child(optionbutton)
	add_child(hsep)
	label.text = display_name
	hsep.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	optionbutton.size_flags_horizontal = SIZE_EXPAND_FILL
	
	for opt in options:
		if opt.type == "item":
			optionbutton.add_item(opt.name)
		elif opt.type == "sep":
			optionbutton.add_separator()
		elif opt.type == "item_ic":
			optionbutton.add_icon_item(opt.icon, opt.name)
	if options.size() > 0:
		optionbutton.selected = 0
	
	optionbutton.connect("item_selected", self, "option_changed")

func _ready():
	for opt in options:
		if opt.type == "item":
			optionbutton.add_item(opt.name)
		elif opt.type == "sep":
			optionbutton.add_separator()
		elif opt.type == "item_ic":
			optionbutton.add_icon_item(opt.icon, opt.name)
	if options.size() > 0:
		optionbutton.selected = 0
	connect("item_added", self, "_item_added")
	inited = true

func option_changed(value):
	set_value(value)
	emit_signal("option_changed", fullpath, value)

func set_value(value):
	current_value = value
	optionbutton.selected = value

func add_item(_name):
	options.append({type="item",name=_name})
	emit_signal("item_added")
	return self

func add_separator():
	options.append({type="sep"})
	return self

func add_icon_item(_texture, _name):
	options.append({type="item_ic",name=_name, icon=_texture})
	return self

func _item_added():
	var val = current_value
	populate_optionbutton()
	set_value(val if val >= 0 else 0)
	pass

func populate_optionbutton():
	optionbutton.clear()
	for opt in options:
		if opt.type == "item":
			optionbutton.add_item(opt.name)
		elif opt.type == "sep":
			optionbutton.add_separator()
		elif opt.type == "item_ic":
			optionbutton.add_icon_item(opt.icon, opt.name)
	if options.size() > 0:
		optionbutton.selected = 0
