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
	
	if fighter.current_state().get("disable_aerial_movement"):
		juke_button.hide()
		juke_dir.hide()

	var spike = fighter.obj_from_name(fighter.spike_projectile)
	if spike:
		if spike.get("can_cancel"):
			spike_button.show()

func is_invalid_state(state):
	return state.type == CharacterState.ActionType.Defense or state.state_name == "DashBackward"

func update_selected_move(move_state):
	.update_selected_move(move_state)
	juke_button.disabled = fighter.juke_pips < fighter.JUKE_PIPS_PER_USE
	if move_state is CharacterState:
		if is_invalid_state(move_state):
			juke_button.set_pressed_no_signal(false)
			juke_button.disabled = true
	elif is_invalid_state(fighter.current_state()):
		juke_button.set_pressed_no_signal(false)
		juke_button.disabled = true
	
	var air_juke = move_state and move_state.get("force_air_juke")
	var different = ((juke_dir.S or juke_dir.N) != air_juke)
	juke_dir.set_S(!fighter.is_grounded())
	juke_dir.set_SW(!fighter.is_grounded())
	juke_dir.set_SE(!fighter.is_grounded())
#	juke_dir.set_Neutral(!fighter.is_grounded())
	juke_dir.set_N((!fighter.is_grounded() and fighter.air_movements_left > 0) or air_juke)
	juke_dir.set_NE((!fighter.is_grounded() and fighter.air_movements_left > 0) or air_juke)
	juke_dir.set_NW((!fighter.is_grounded() and fighter.air_movements_left > 0) or air_juke)
	juke_dir.call_deferred("try_hide_sections")
	
	juke_button.visible = fighter.juke_pips >= fighter.JUKE_PIPS_PER_USE and fighter.opponent.combo_count <= 0
	juke_dir.visible = fighter.juke_pips >= fighter.JUKE_PIPS_PER_USE and fighter.opponent.combo_count <= 0
	
	if fighter.current_state().get("disable_aerial_movement"):
		juke_button.hide()
		juke_dir.hide()
	
	var current = juke_dir.pressed_button.name

	if different and fighter.is_grounded():
		if !(current == "E" or current == "W"): 
			juke_dir.set_sensible_default(juke_dir.pressed_button.name, false)
		pass

	if $"%JukeButton".disabled:
		$"%JukeButton".set_pressed_no_signal(false)

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
#	if !button_pressed:
#		juke_dir.set_sensible_default("Neutral")
	pass
	
func _on_JukeDir_data_changed():
	$"%JukeButton".set_pressed_no_signal($"%JukeButton".visible)
	if $"%JukeButton".disabled:
		$"%JukeButton".set_pressed_no_signal(false)
