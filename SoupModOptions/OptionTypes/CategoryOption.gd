extends "res://SoupModOptions/OptionTypes/ModOptionObject.gd"

var option_list
var list_panel:PanelContainer
var titlebar:PanelContainer
var button:CheckButton

func _build():
	var vbox1 = VBoxContainer.new()
	add_child(vbox1)
	vbox1.name = "CategoryContainer"
		
	titlebar = PanelContainer.new()
	vbox1.add_child(titlebar)
	titlebar.set_theme_type_variation("CategoryTitlebar")
		
	
	button = CheckButton.new()
	titlebar.add_child(button)
	button.set_theme_type_variation("CategoryButton")
	button.text = display_name
	button.pressed = true
	
	list_panel = PanelContainer.new()
	vbox1.add_child(list_panel)
	list_panel.name = "OptionsContainer"
	list_panel.set_theme_type_variation("CategoryOptions")
	option_list = VBoxContainer.new()
	list_panel.add_child(option_list)
	option_list.name = "OptionList"
	
	button.connect("toggled", self, "category_toggled")

func _ready():
	pass

func category_toggled(value):
	list_panel.visible = value
