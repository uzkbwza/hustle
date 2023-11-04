extends PlayerExtra


onready var spike_button = $"%DisableSpikeButton"

func _ready():
	spike_button.connect("toggled", self, "_on_disable_spike_toggled")

#	end_bomb_button.connect("toggled", self, "_on_bomb_button_toggled")

func _on_disable_spike_toggled(_on):
	emit_signal("data_changed")


func show_options():
	spike_button.hide()
	spike_button.set_pressed_no_signal(true)
	var spike = fighter.obj_from_name(fighter.spike_projectile)
	if spike:
		if spike.get("can_cancel"):
			spike_button.show()

func update_selected_move(move_state):
	.update_selected_move(move_state)


func get_extra():
	var extra = {
		"spike_enabled": spike_button.pressed,

	}
	return extra

func reset():
	spike_button.set_pressed_no_signal(true)
