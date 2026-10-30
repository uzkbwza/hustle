extends PlayerExtra

const SIGHT_COST : int = 1

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
	print("[DRAWDBG] show_options id=", fighter.id, " (hiding) state=", fighter.current_state().state_name, " ctick=", fighter.current_state().current_tick)
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

	# Reveal the Draw toggle whenever a draw-cancelable move is in reach, so the
	# player can arm the cancel via the hold button without selecting it first.
	# Hold is the default selection here, so the draw is conditional.
	$"%ShootButton".visible = draw_cancel_available()
	$"%ShootButton".text = "Draw on Block" if fighter.draw_cancel_on_block_only(fighter.current_state(), true) else "Draw"
	print("[DRAWDBG] reset id=", fighter.id, " state=", fighter.current_state().state_name, " ctick=", fighter.current_state().current_tick, " vis=", $"%ShootButton".visible)

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

func update_sight_button(move = fighter.current_state()):
	if move == null:
		move = fighter.current_state() #a redundant failsafe
	
	var move_cost = move.super_level_
	if move.get("super_level"): #why are there separate super levels???
		move_cost = max(move.super_level_, move.super_level)

	var total_cost = move_cost + SIGHT_COST
	sight_button.disabled = not (fighter.supers_available >= total_cost)
	if sight_button.disabled:
		sight_button.set_pressed_no_signal(false)
		
	if "Knockdown" in fighter.current_state().state_name:
		sight_button.hide()

# Hold case: holding continues the current move, so a draw is reachable only if
# that move can still produce one from its current tick (an unfired try_shoot, or
# a hitbox that can still land on block). Menu moves aren't relevant here — they
# get the toggle when actually selected.
#
# Once bullet_cancelling has latched true the draw is already committed for this
# move: it fires on block no matter what, and the latch isn't cleared by
# un-toggling (only by firing or the move ending). So the toggle is dead weight
# from here on — hide it instead of letting the player flip a switch that does
# nothing.
func draw_cancel_available():
	if fighter.bullet_cancelling:
		return false
	return fighter.draw_cancel_possible(fighter.current_state(), true)

func update_selected_move(move_state):
	.update_selected_move(move_state)
	# A DIFFERENT move we'd cancel into is a fresh cast (starts at tick 0), so its
	# draw is checked progress-free. But "hold" (null) and the in-progress move
	# being re-displayed must respect progress: a try_shoot that already passed in
	# this move won't fire again, so offering the toggle there is a dead button.
	# Without this, a whiffed Horiz. Slash in recovery (its try_shoot long gone)
	# still lit the toggle every tick the waiting opponent kept the game paused.
	# Re-selecting the move we're already in is the exception: it re-enters from
	# tick 0, so the draw is reachable again. selected_move_will_restart (the pick
	# isn't locked in yet) flags that, so the same-state re-pick counts as fresh.
	var fresh = move_state != null and (move_state != fighter.current_state() or selected_move_will_restart)
	var show_draw = fighter.draw_cancel_possible(move_state, false) if fresh else draw_cancel_available()
	$"%ShootButton".visible = show_draw
	# "Draw on Block" only for moves whose sole draw route is the on-block one;
	# a try_shoot move draws on hit/whiff too, so it stays "Draw".
	var label_state = move_state if fresh else fighter.current_state()
	$"%ShootButton".text = "Draw on Block" if fighter.draw_cancel_on_block_only(label_state, !fresh) else "Draw"
	print("[DRAWDBG] usm id=", fighter.id, " move=", (move_state.state_name if move_state else "null"), " cur=", fighter.current_state().state_name, " ctick=", fighter.current_state().current_tick, " fresh=", fresh, " vis=", show_draw)
	if fighter.after_image_object != null:
		$"%DetonateButton".show()
		update_tp_button()
	sight_button.visible = (!move_state or (move_state.state_name != "Foresight" and move_state.state_name != "ForesightNeutral")) and fighter.after_image_object == null
	update_sight_button(move_state)

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
