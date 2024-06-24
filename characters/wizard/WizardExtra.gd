extends PlayerExtra

onready var hover_button = $"%HoverButton"
#onready var end_hover_button = $"%EndHoverButton"
onready var fast_fall_button = $"%FastFallButton"
onready var orb_push = $"%OrbPush"
onready var explode_button = $"%ExplodeButton"
#onready var launch_direction = $"%LaunchDir"
#onready var shoot_button = $"%ShootButton"
#onready var launch_container = $"%LaunchContainer"
onready var lock_button = $"%LockButton"

func _ready():
	hover_button.connect("toggled", self, "_on_hover_button_toggled")
	fast_fall_button.connect("toggled", self, "_on_fast_fall_button_toggled")
	orb_push.connect("data_changed", self, "emit_signal", ["data_changed"])
#	launch_direction.connect("data_changed", self, "emit_signal", ["data_changed"])
	explode_button.connect("pressed", self, "emit_signal", ["data_changed"])
	lock_button.connect("pressed", self, "emit_signal", ["data_changed"])
#	shoot_button.connect("pressed", self, "emit_signal", ["data_changed"])
#	shoot_button.connect("toggled", self, "_on_shoot_button_toggled")
#	end_hover_button.connect("toggled", self, "_on_hover_button_toggled")

func on_data_changed():
	if fighter.orb_projectile != null:
		orb_push.visible = true
		if lock_button.pressed:
			orb_push.visible = false

func update_selected_move(move_state):
	.update_selected_move(move_state)
	$"%HoverButton".disabled = false
	$"%FastFallButton".disabled = false
#	if move_state and move_state.get("IS_NEW_PARRY") and fighter.current_state().get("disable_aerial_movement"):
#		$"%HoverButton".set_pressed_no_signal(false)
#		$"%HoverButton".disabled = true
#		$"%FastFallButton".set_pressed_no_signal(false)
#		$"%FastFallButton".disabled = true
	if fighter.current_state().get("disable_aerial_movement"):
		$"%HoverButton".set_pressed_no_signal(false)
		$"%HoverButton".disabled = true
		$"%FastFallButton".set_pressed_no_signal(false)
		$"%FastFallButton".disabled = true
	if (move_state and move_state is GroundedParryState) or (move_state == null and fighter.current_state() is GroundedParryState):
		$"%FastFallButton".set_pressed_no_signal(false)
		$"%FastFallButton".disabled = true

func _on_hover_button_toggled(on):
	if on:
		fast_fall_button.set_pressed_no_signal(false)
	emit_signal("data_changed")

func _on_fast_fall_button_toggled(on):
	if on:
		hover_button.set_pressed_no_signal(false)
	emit_signal("data_changed")

func _on_shoot_button_toggled(on):
	$"%LaunchDir".visible = on

func reset():
	orb_push.set_dir("Neutral")
	var is_hurt = fighter.current_state() != CharacterHurtState
	explode_button.set_pressed_no_signal(fighter.detonating_bombs and is_hurt)
	fast_fall_button.set_pressed_no_signal(fighter.fast_falling and is_hurt)
	hover_button.set_pressed_no_signal(fighter.hovering and is_hurt)
	lock_button.set_pressed_no_signal(false)
	if fighter.orb_projectile != null:
		var orb = fighter.obj_from_name(fighter.orb_projectile)
		lock_button.set_pressed_no_signal(orb.locked)
	if fighter.current_state().get("disable_aerial_movement"):
		$"%HoverButton".set_pressed_no_signal(false)
		$"%HoverButton".disabled = true
		$"%FastFallButton".set_pressed_no_signal(false)
		$"%FastFallButton".disabled = true

func show_options():

	orb_push.hide()
	orb_push.init()
	lock_button.hide()
	explode_button.hide()
	orb_push.visible = fighter.orb_projectile != null
	
	var orb = fighter.obj_from_name(fighter.orb_projectile)
	lock_button.visible = orb != null and orb.lock_cooldown == 0
	lock_button.set_pressed_no_signal(orb != null and orb.locked)
	
	if lock_button.pressed:
		orb_push.visible = false
#	launch_container.visible = fighter.boulder_projectile != null
	hover_button.hide()
	fast_fall_button.hide()
	fast_fall_button.set_pressed_no_signal(fighter.fast_falling)
	
	if !fighter.current_state().get("disable_aerial_movement"):
		hover_button.set_pressed_no_signal(fighter.hovering)
	if fast_fall_button.pressed and hover_button.pressed:
		fast_fall_button.set_pressed_no_signal(false)
#	end_hover_button.hide()
#	end_hover_button.set_pressed_no_signal(false)
	if fighter.can_hover() or fighter.hovering:
		hover_button.show()
	if "Knockdown" in fighter.current_state().name:
		hover_button.hide()
		hover_button.set_pressed_no_signal(false)
	
	if fighter.can_fast_fall():
		fast_fall_button.show()
	if fighter.spark_bombs:
		explode_button.show()

func get_extra():
	var extra = {
		"hover": hover_button.pressed,
		"fast_fall": fast_fall_button.pressed,
		"detonate": explode_button.pressed,
		"orb_push": orb_push.get_data(),
		"lock_orb": lock_button.pressed,
#		"launch_dir": launch_direction.get_data(),
#		"launch": shoot_button.pressed,
	}
	return extra
