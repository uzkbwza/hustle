extends Control


var char_container
onready var line_edit = $"%LineEdit"
onready var show_all_button = $"%ShowAllButton"
onready var random_button = $"%RandomButton"
onready var clear_button = $"%ClearButton"
onready var options_button = $"%OptionsButton"
onready var options_menu = $"%OptionsList"
onready var options_panel = $"%OptionsContainer"


func _ready():
	char_container = get_parent().get_node("%CharacterButtonContainer")
	connect("visibility_changed", self, "_on_visibility_changed")
	line_edit.connect("text_changed", self, "_on_text_changed")
	random_button.connect("pressed", self, "pick_random")
	clear_button.connect("pressed", self, "clear_search")
	options_button.connect("pressed", self, "toggle_options_list")


# this is here just to fight the ui trying to make things visible or invisible for no reason
# works beceause of process priority
# also can't just put this in the CharacterSelect overrider script
#    because apparently _process happens before the inherited _process
func _process(delta):
	visible = true
	if is_visible_in_tree():
		var text : String = line_edit.text
		var has_no_text : bool = (text != "")
		clear_button.visible = has_no_text
		show_all_button.visible = has_no_text
		var lower_text = text.to_lower()
		var showing_all = show_all_button.pressed
		for child in char_container.get_children():
			if child is Button:
				child.visible = showing_all or not has_no_text or (lower_text in child.text.to_lower())



func _on_text_changed(new_text):
	var text : String = line_edit.text
	var lower_text : = text.to_lower()
	for child in char_container.get_children():
		if child is Button:
			child.modulate = Color(1, 1, 1, 1) if (text == "") or (lower_text in child.text.to_lower()) else Color(0.5, 0.5, 0.5, 0.25)


func _on_visibility_changed():
	for child in options_menu.get_children():
		child.queue_free()
	var mod_list_container = get_node("/root/Main/%ModListButtonContainer")
	for button in mod_list_container.get_children():
		if button is Button:
			var new_button = Button.new()
			new_button.text = button.text
			new_button.size_flags_horizontal = SIZE_EXPAND_FILL
			new_button.connect("pressed", self, "open_option_button", [ button ])
			options_menu.add_child(new_button)
	clear_search()
	options_panel.visible = false


func pick_random():
	var choices = []
	for button in char_container.get_children():
		if button is Button and not button.disabled:
			choices.append(button)
	if choices.size() == 0:
		return
	var picked : Button = choices[randi() % choices.size()]
	picked.emit_signal("pressed")


func clear_search():
	line_edit.text = ""
	_on_text_changed("")


func open_option_button(button):
	options_panel.visible = false
	button.emit_signal("pressed")


func toggle_options_list():
	options_panel.visible = not options_panel.visible
