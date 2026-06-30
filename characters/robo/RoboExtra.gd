extends PlayerExtra

var current_dir = null

var jump_selected

onready var bounce = $"%Bounce"
onready var loic = $"%LOIC"



func _ready():
	$"%FlyDir".connect("data_changed", self, "emit_signal", ["data_changed"])
	$"%Bounce".connect("data_changed", self, "emit_signal", ["data_changed"])
	$"%FlyEnabled".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%ArmorEnabled".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%NadeActive".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%PullEnabled".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%PullEnabled".connect("pressed", $"%ArmorEnabled", "set_pressed_no_signal", [false])
	$"%ArmorEnabled".connect("pressed", $"%PullEnabled", "set_pressed_no_signal", [false])
	$"%DriveCancel".connect("pressed", self, "emit_signal", ["data_changed"])
	loic.connect("data_changed", self, "emit_signal", ["data_changed"])
	
func get_extra():
	current_dir = $"%FlyDir".get_dir()
	return {
		"fly_dir": $"%FlyDir".get_data() if $"%FlyDir".is_visible_in_tree() else fighter.flying_dir,
		"fly_enabled": $"%FlyEnabled".pressed if $"%FlyEnabled".is_visible_in_tree() else (fighter.flying_dir != null),
		"armor_enabled": $"%ArmorEnabled".pressed,
		"nade_activated": $"%NadeActive".pressed and $"%NadeActive".visible,
		"pull_enabled": $"%PullEnabled".pressed and $"%PullEnabled".visible,
		"drive_cancel": drive_pressed() if fighter.stance != "Drive" else !drive_pressed(),
		"bounce": bounce.get_data(),
		"honk": $"%HonkEnabled".pressed
	}
if loic.is_visible_in_tree():
		extra["loic_dir"] = loic.get_data()
	return extra

func drive_pressed():
	return $"%DriveCancel".pressed and $"%DriveCancel".visible

# Hold case: holding continues the current move, so a drive cancel is reachable
# only if that move can still produce one from its current tick (an unfired
# try_drive_cancel command, which both the on-hit and on-block paths require).
# Menu moves aren't relevant here — they get the toggle when actually selected.
func drive_cancel_available():
	return fighter.drive_cancel_possible(fighter.current_state(), true)

func update_selected_move(move_state):
	.update_selected_move(move_state)
	$"%ArmorEnabled".disabled = false
	$"%FlyEnabled".disabled = false

	# Whiff-block lockout — same gate NewParry.is_usable uses to refuse a
	# fresh parry after a whiffed one. If the current state is a parry that
	# didn't catch anything (and we're not mid-combo), disable the armor
	# toggle so the player can't queue armor straight out of a whiff block.
	# Push blocks are exempt — NewParry.is_usable lets you act freely out of a
	# whiffed push block (the trailing `or push`), so armor must too.
	var current = fighter.current_state()
	if current and current.get("IS_NEW_PARRY") \
			and !current.parried and !current.autoguard \
			and !current.push and fighter.combo_count <= 0:
		$"%ArmorEnabled".set_pressed_no_signal(false)
		$"%ArmorEnabled".disabled = true

	if move_state is CharacterState:
		if move_state.name != "Step" and (\
		move_state.type == CharacterState.ActionType.Defense \
		or move_state.type == CharacterState.ActionType.Movement):
			$"%ArmorEnabled".set_pressed_no_signal(false)
			$"%ArmorEnabled".disabled = true
	if move_state is RollDodge:
		$"%FlyEnabled".set_pressed_no_signal(false)
		$"%FlyEnabled".disabled = true
	if move_state and move_state.get("IS_NEW_PARRY") and fighter.in_blockstring:
		$"%FlyEnabled".set_pressed_no_signal(false)
		$"%FlyEnabled".disabled = true
	if fighter.in_blockstring and fighter.current_state().get("IS_NEW_PARRY") and move_state == null:
		$"%FlyEnabled".set_pressed_no_signal(false)
		$"%FlyEnabled".disabled = true
#	if fighter.is_grounded():
#		$"%FlyDir".hide()
#		$"%FlyEnabled".hide()
#		if move_state and move_state.name == "Jump":
#			jump_selected = true
#			$"%FlyDir".show()
#			$"%FlyEnabled".show()
#		else:
#			$"%FlyEnabled".set_pressed_no_signal(false)

	# A DIFFERENT move we'd cancel into is a fresh cast (starts at tick 0), checked
	# progress-free. "Hold" (null) and the in-progress move being re-displayed
	# respect progress: a try_drive_cancel that already passed in this move won't
	# fire again, so the toggle there is dead (e.g. a whiffed move in recovery while
	# a waiting opponent keeps the game paused).
	# Re-selecting the move we're already in is the exception: it re-enters from
	# tick 0 (e.g. a second consecutive Floor It out of Floor It), so the cancel is
	# reachable again. selected_move_will_restart (the selection isn't locked in
	# yet) flags that, so the same-state pick reads as fresh, not a held continuation.
	var fresh = move_state != null and (move_state != fighter.current_state() or selected_move_will_restart)
	$"%DriveCancel".visible = fighter.drive_cancel_possible(move_state, false) if fresh else drive_cancel_available()
	$"%DriveCancel".text = "Drive"
	if move_state:
		if move_state.is_grab and $"%ArmorEnabled".pressed:
			can_feint = false

	if fighter.current_state().get("disable_aerial_movement"):
		$"%FlyEnabled".set_pressed_no_signal(false)
		$"%FlyEnabled".disabled = true

func show_options():
	$"%FlyDir".hide()
	bounce.hide()
	loic.hide()
	$"%FlyEnabled".hide()
	$"%ArmorEnabled".hide()
	$"%NadeActive".hide()
	$"%PullEnabled".hide()
	$"%HonkEnabled".hide()
	$"%FlyDir".set_dir("Neutral")
	$"%FlyDir".facing = fighter.get_opponent_dir()
	$"%FlyDir".init()
	$"%DriveCancel".hide()
	if current_dir:
		$"%FlyDir".set_dir(current_dir)
#	$"%FlyEnabled".set_pressed_no_signal(false)
	var nade = fighter.obj_from_name(fighter.grenade_object)
	if fighter.stance == "Drive" and fighter.honking_cooldown <= 0:
		$"%HonkEnabled".show()
	if nade:
		if !nade.active:
			$"%NadeActive".show()
	if fighter.magnet_installed:
		$"%PullEnabled".show()
	if fighter.is_grounded() and !jump_selected:
		$"%FlyDir".hide()
		$"%FlyEnabled".hide()
	else:
		if fighter.air_option_bar > 0:
			$"%FlyDir".show()
			$"%FlyEnabled".show()
			$"%FlyEnabled".set_pressed_no_signal(fighter.fly_ticks_left > 0)
		elif fighter.flying_dir != null:
			$"%FlyEnabled".show()
			$"%FlyEnabled".set_pressed_no_signal(fighter.fly_ticks_left > 0)
	if fighter.armor_pips > 0:
		$"%ArmorEnabled".show()
#	if fighter.current_state().state_name == "WhiffInstantCancel":
#		$"%ArmorEnabled".hide()
	
	if fighter.current_state().get("disable_aerial_movement"):
		$"%FlyEnabled".set_pressed_no_signal(false)
		$"%FlyEnabled".disabled = true
		$"%FlyDir".hide()
	if fighter.orbital_strike_out:
		loic.show()
#		var obj = fighter.obj_from_name(fighter.orbital_strike_projectile)
#		if obj:
#			if obj.active:
#				loic.hide()

func reset():
	if fighter.flying_dir:
		$"%FlyDir".set_dir_from_data(fighter.flying_dir)
		$"%FlyEnabled".set_pressed_no_signal(true)
	else:
		$"%FlyEnabled".set_pressed_no_signal(false)
	loic.set_dir_from_data({"x": fighter.loic_dir, "y": 0})
	$"%ArmorEnabled".set_pressed_no_signal(false)
	$"%NadeActive".set_pressed_no_signal(false)
	$"%PullEnabled".set_pressed_no_signal(false)
	$"%HonkEnabled".set_pressed_no_signal(false)
	$"%DriveCancel".set_pressed_no_signal(fighter.stance == "Drive")
	# Reveal the Drive toggle whenever a drive-cancelable move is in reach, so the
	# player can arm the cancel via the hold button without selecting it first.
	# Hold is the default selection here, so the drive cancel is conditional.
	$"%DriveCancel".visible = drive_cancel_available()
	$"%DriveCancel".text = "Drive"

	if fighter.current_state().get("disable_aerial_movement"):
		$"%FlyEnabled".set_pressed_no_signal(false)
		$"%FlyEnabled".disabled = true

func on_data_changed():
#	bounce.visible = $"%NadeActive".pressed
#	if $"%ArmorEnabled".pressed and $"%PullEnabled".pressed:
#		$"%PullEnabled".set_pressed_no_signal(false)
	pass


func _on_FlyDir_data_changed():
	$"%FlyEnabled".set_pressed_no_signal(true)
	pass # Replace with function body.
