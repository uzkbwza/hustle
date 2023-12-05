extends PlayerExtra

onready var spike_button = $"%DisableSpikeButton"
onready var juke_button = $"%JukeButton"
onready var juke_dir = $"%JukeDir"

func _ready():
	spike_button.connect("toggled", self, "_on_data_changed")
	juke_button.connect("toggled", self, "_on_data_changed")
	juke_dir.connect("data_changed", self, "_on_data_changed", [null])

func _on_data_changed(_on):
	emit_signal("data_changed")

func show_options():
	spike_button.hide()
	spike_button.set_pressed_no_signal(true)
	juke_button.show()
	if fighter.current_state().state_name == "Knockdown":
		juke_button.hide()
		juke_dir.hide()
		return

	var spike = fighter.obj_from_name(fighter.spike_projectile)
	if spike:
		if spike.get("can_cancel"):
			spike_button.show()
	juke_dir.set_S(!fighter.is_grounded())
#	juke_dir.set_Neutral(!fighter.is_grounded())
	juke_dir.set_N(!fighter.is_grounded() and fighter.air_movements_left > 0)
	juke_dir.call_deferred("try_hide_sections")
	juke_button.visible = fighter.juke_pips >= fighter.JUKE_PIPS_PER_USE
	juke_dir.visible = fighter.juke_pips >= fighter.JUKE_PIPS_PER_USE
	juke_dir.set_sensible_default("Neutral")

func update_selected_move(move_state):
	.update_selected_move(move_state)
	juke_button.disabled = fighter.juke_pips < fighter.JUKE_PIPS_PER_USE
	if move_state is CharacterState:
		if move_state.type == CharacterState.ActionType.Defense or move_state.state_name == "DashBackward":
			juke_button.set_pressed_no_signal(false)
			juke_button.disabled = true


func get_extra():
	var extra = {
		"spike_enabled": spike_button.pressed,
		"juke_dir": juke_dir.get_data() if juke_button.pressed and juke_button.is_visible_in_tree() else null
	}
	return extra

func reset():
	spike_button.set_pressed_no_signal(true)
	juke_button.set_pressed_no_signal(false)
#	juke_dir.hide()

func _on_JukeButton_toggled(button_pressed):
#	juke_dir.visible = button_pressed
	pass
	

func _on_JukeDir_data_changed():
	$"%JukeButton".set_pressed_no_signal($"%JukeButton".visible)
	pass # Replace with function body.
