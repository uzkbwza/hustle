extends PlayerExtra

var can_shoot = false

func _ready():
	Utils.pass_signal_along($"%ShootButton", self, "pressed", "data_changed")

func get_extra():
	return {
		"gun_cancel": $"%ShootButton".pressed and $"%ShootButton".visible
	}

func show_options():
	$"%ShootButton".hide()
	$"%ShootButton".pressed = false
	return

func reset():
	selected_move = null
	$"%ShootButton".hide()
	$"%ShootButton".pressed = false
	pass

func update_selected_move(move_state):
	.update_selected_move(move_state)
	if move_state:
		$"%ShootButton".visible = ("try_shoot" in move_state.host_commands.values()) and fighter.can_bullet_cancel()
