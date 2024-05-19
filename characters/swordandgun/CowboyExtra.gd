extends PlayerExtra

var can_shoot = false
var aerial = false
var grounded = false

onready var sight_button = $"%SightButton"


func _ready():
	Utils.pass_signal_along($"%ShootButton", self, "pressed", "data_changed")
	Utils.pass_signal_along($"%DetonateButton", self, "pressed", "data_changed")
	Utils.pass_signal_along($"%TpButton", self, "pressed", "data_changed")
	Utils.pass_signal_along($"%MilkButton", self, "pressed", "data_changed")
	Utils.pass_signal_along(sight_button, self, "pressed", "data_changed")


func get_extra():
	return {
		"gun_cancel": $"%ShootButton".pressed and $"%ShootButton".visible,
		"detonate": $"%DetonateButton".pressed and $"%DetonateButton".visible,
		"shift": $"%TpButton".pressed and $"%TpButton".visible,
		"drift": $"%MilkButton".pressed and $"%MilkButton".visible,
		"hindsight": sight_button.pressed and sight_button.visible,
		"input_aerial": aerial,
		"input_grounded": grounded,
	}

func show_options():
	$"%ShootButton".hide()
	$"%ShootButton".pressed = false
	$"%DetonateButton".hide()
	$"%DetonateButton".pressed = false
	$"%TpButton".hide()
	$"%TpButton".pressed = false
	sight_button.pressed = false

func reset():
	selected_move = null
	sight_button.pressed = false
	sight_button.disabled = true
	sight_button.hide()
	$"%ShootButton".hide()
	$"%ShootButton".pressed = false
	$"%DetonateButton".hide()
	$"%DetonateButton".pressed = false
	$"%MilkButton".pressed = false
	$"%TpButton".hide()
	$"%MilkButton".hide()
	$"%TpButton".pressed = false
	if fighter.after_image_object != null:
		$"%DetonateButton".show()
		update_tp_button()
	else:
		sight_button.show()
		update_sight_button()
	if "Knockdown" in fighter.current_state().state_name:
		sight_button.hide()
	
	block_disable()

func update_tp_button():
		var move = fighter.current_state()
		$"%TpButton".disabled = false
		$"%TpButton".show()
		if fighter.is_grounded() or fighter.air_movements_left > 0:
			$"%TpButton".show()
		else:
			$"%TpButton".hide()
		if (selected_move and selected_move.type == CharacterState.ActionType.Defense):
			$"%TpButton".disabled = true
			$"%TpButton".set_pressed_no_signal(false)
		var obj = fighter.obj_from_name(fighter.after_image_object)
#		if obj:
		if obj:
			$"%MilkButton".visible = obj.is_grounded() != fighter.is_grounded()
			$"%MilkButton".disabled =  fighter.supers_available < fighter.DRIFT_SUPERS
			
		if fighter.after_image_object != null:
			$"%DetonateButton".show()
			$"%DetonateButton".disabled = false
		block_disable()

func block_disable():
	if fighter.current_state().get("disable_aerial_movement"):
		$"%TpButton".set_pressed_no_signal(false)
		$"%TpButton".disabled = true
		$"%DetonateButton".set_pressed_no_signal(false)
		$"%DetonateButton".disabled = true
		$"%MilkButton".set_pressed_no_signal(false)
		$"%MilkButton".disabled = true
		$"%SightButton".set_pressed_no_signal(false)
		$"%SightButton".disabled = true

func update_sight_button():
	sight_button.disabled = !(fighter.supers_available > 0)
	if "Knockdown" in fighter.current_state().state_name:
		sight_button.hide()

func update_selected_move(move_state):
	.update_selected_move(move_state)
	if move_state:
		var state_children = move_state.get_children()
		var has_command = false
		for child in state_children:
			if child is HostCommand:
				if child.command == "try_shoot":
					has_command = true
					break
		var can_draw_cancel = true
		if move_state.has_method("can_draw_cancel"):
			can_draw_cancel = move_state.can_draw_cancel()
		$"%ShootButton".visible = (has_command or "try_shoot" in move_state.host_commands.values()) and fighter.can_bullet_cancel() and can_draw_cancel
	if fighter.after_image_object != null:
		$"%DetonateButton".show()
		update_tp_button()
	sight_button.visible = (!move_state or (move_state.state_name != "Foresight" and move_state.state_name != "ForesightNeutral")) and fighter.after_image_object == null
	update_sight_button()

	var obj = fighter.obj_from_name(fighter.after_image_object)
	aerial = false
	grounded = false
	if obj:
		if $"%TpButton".pressed: 
			aerial = obj.get_pos().y < 0
			grounded = obj.get_pos().y == 0
		elif $"%MilkButton".pressed:
			aerial = fighter.is_grounded()
			grounded = !fighter.is_grounded()

	block_disable()

func _on_DetonateButton_toggled(button_pressed):
	$"%TpButton".set_pressed_no_signal(false)
	$"%MilkButton".set_pressed_no_signal(false)
	block_disable()

func _on_TpButton_toggled(button_pressed):
	$"%DetonateButton".set_pressed_no_signal(false)
	$"%MilkButton".set_pressed_no_signal(false)
	block_disable()

func _on_MilkButton_toggled(button_pressed):
	$"%DetonateButton".set_pressed_no_signal(false)
	$"%TpButton".set_pressed_no_signal(false)
	block_disable()
