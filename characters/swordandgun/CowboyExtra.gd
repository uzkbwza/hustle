extends PlayerExtra

var can_shoot = false
var aerial = false
var grounded = false

func _ready():
	Utils.pass_signal_along($"%ShootButton", self, "pressed", "data_changed")
	Utils.pass_signal_along($"%DetonateButton", self, "pressed", "data_changed")
	Utils.pass_signal_along($"%TpButton", self, "pressed", "data_changed")


func get_extra():
	return {
		"gun_cancel": $"%ShootButton".pressed and $"%ShootButton".visible,
		"detonate": $"%DetonateButton".pressed and $"%DetonateButton".visible,
		"shift": $"%TpButton".pressed and $"%TpButton".visible,
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

func reset():
	selected_move = null
	$"%ShootButton".hide()
	$"%ShootButton".pressed = false
	$"%DetonateButton".hide()
	$"%DetonateButton".pressed = false
	$"%TpButton".hide()
	$"%TpButton".pressed = false
	if fighter.after_image_object != null:
		$"%DetonateButton".show()
		update_tp_button()


func update_tp_button():
		$"%TpButton".disabled = false
		$"%TpButton".show()
		if fighter.is_grounded() or fighter.air_movements_left > 0:
			$"%TpButton".show()
		else:
			$"%TpButton".hide()
		if selected_move and selected_move.type == CharacterState.ActionType.Defense:
			$"%TpButton".disabled = true

func update_selected_move(move_state):
	.update_selected_move(move_state)
	if move_state:
		$"%ShootButton".visible = ("try_shoot" in move_state.host_commands.values()) and fighter.can_bullet_cancel()
	if fighter.after_image_object != null:
		$"%DetonateButton".show()
		update_tp_button()

	var obj = fighter.obj_from_name(fighter.after_image_object)
	aerial = false
	grounded = false
	if obj:
		if $"%TpButton".pressed: 
			aerial = obj.get_pos().y < 0
			grounded = obj.get_pos().y == 0

func _on_DetonateButton_toggled(button_pressed):
	$"%TpButton".set_pressed_no_signal(false)
	pass # Replace with function body.


func _on_TpButton_toggled(button_pressed):
	$"%DetonateButton".set_pressed_no_signal(false)
	pass # Replace with function body.
