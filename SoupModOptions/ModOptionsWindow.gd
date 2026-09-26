extends Window

var ModOptions
var cur_menu = null
var menus:Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	hint_tooltip=""
	ModOptions = load("res://SoupModOptions/ModOptions.gd").new()
	ModOptions.menu = self
	get_tree().get_current_scene().call_deferred("add_child", ModOptions, true)
	$"%CloseButton".connect("pressed", self, "_close_clicked")
	hide()
	

func clear_menu():
	for tab in $"%Tabs".get_children():
		tab.queue_free()
	for menu in $"%MenuContainer".get_children():
		menu.queue_free()
	pass
	
func fill_menu():
	pass

func add_menu_from_node(menuNode):
	var menuButton = load("res://SoupModOptions/MOTabBtn.gd").new()
	menuButton.toggle_mode = true
	menuButton.text = menuNode.tab_name
	#menuButton.flat = true
	menuButton.set("mouse_default_cursor_shape", 2)
	#menuButton.set("custom_colors/font_color_hover", Color(100.0, 0.2, 0.23, 1.0))
	menuNode.tab_btn = menuButton
	menuNode.visible = false
	menuButton.menu_node = menuNode
	menuButton.connect("pressed", self, "_tab_clicked", [menuButton])
	menus[menuNode.name] = menuNode
	$"%Tabs".add_child(menuButton)
	menuButton.set_theme_type_variation("TabButton")
	$"%MenuContainer".add_child(menuNode)
	

#func add_menu(node_path):
#	var menuNode = load(node_path).instance()
#	var menuButton = ModOptionsTabButton.new()
#	menuButton.toggle_mode = true
#	menuButton.text = menuNode.tab_name
#	menuButton.flat = true
#	menuButton.set("mouse_default_cursor_shape", 2)
#	menuButton.set("custom_colors/font_color_hover", Color(100.0, 0.2, 0.23, 1.0))
#	menuNode.tab_btn = menuButton
#	menuNode.visible = false
#	menuButton.menu_node = menuNode
#	menuButton.connect("pressed", self, "_tab_clicked", [menuButton])
#	$"%Tabs".add_child(menuButton)
#	$"%MenuContainer".add_child(menuNode)


func show_menu(node:Node):
	if cur_menu != null:
		cur_menu.hide()
		cur_menu.tab_btn.pressed = false
		if cur_menu.needs_to_save:
			ModOptions.save_settings(cur_menu.name)
	node.show()
	node.tab_btn.pressed = true
	cur_menu = node

func _tab_clicked(node:Node):
	if cur_menu != node:
		show_menu(node.menu_node)

func _close_clicked():
	hide()
	if cur_menu:
		cur_menu.hide()
	for menu in menus.values():
		if menu.needs_to_save:
			ModOptions.save_settings(menu.name)

func _mainmenu_button_pressed():
	show()
