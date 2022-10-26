extends PlayerExtra

onready var hover_button = $"%HoverButton"
#onready var end_hover_button = $"%EndHoverButton"

func _ready():
	hover_button.connect("toggled", self, "_on_hover_button_toggled")
#	end_hover_button.connect("toggled", self, "_on_hover_button_toggled")

func _on_hover_button_toggled(_on):
	emit_signal("data_changed")

func show_options():
	hover_button.hide()
	hover_button.set_pressed_no_signal(fighter.hovering)
#	end_hover_button.hide()
#	end_hover_button.set_pressed_no_signal(false)
	if fighter.can_hover() or fighter.hovering:
		hover_button.show()
#	if fighter.hovering:
#		end_hover_button.show()

func get_extra():
	var extra = {
		"hover": hover_button.pressed
	}
	return extra
