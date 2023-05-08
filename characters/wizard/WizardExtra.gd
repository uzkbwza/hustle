extends PlayerExtra

onready var hover_button = $"%HoverButton"
#onready var end_hover_button = $"%EndHoverButton"
onready var fast_fall_button = $"%FastFallButton"
onready var orb_push = $"%OrbPush"
onready var explode_button = $"%ExplodeButton"

func _ready():
	hover_button.connect("toggled", self, "_on_hover_button_toggled")
	fast_fall_button.connect("toggled", self, "_on_fast_fall_button_toggled")
	orb_push.connect("data_changed", self, "emit_signal", ["data_changed"])
	explode_button.connect("pressed", self, "emit_signal", ["data_changed"])
#	end_hover_button.connect("toggled", self, "_on_hover_button_toggled")

func _on_hover_button_toggled(on):
	if on:
		fast_fall_button.set_pressed_no_signal(false)
	emit_signal("data_changed")

func _on_fast_fall_button_toggled(on):
	if on:
		hover_button.set_pressed_no_signal(false)
	emit_signal("data_changed")

func reset():
	orb_push.set_dir("Neutral")
	var is_hurt = fighter.current_state() != CharacterHurtState
	explode_button.set_pressed_no_signal(fighter.detonating_bombs and is_hurt)
	fast_fall_button.set_pressed_no_signal(fighter.fast_falling and is_hurt)
	hover_button.set_pressed_no_signal(fighter.hovering and is_hurt)

func show_options():
	orb_push.hide()
	orb_push.init()
	explode_button.hide()
	orb_push.visible = fighter.orb_projectile != null
	hover_button.hide()
	fast_fall_button.hide()
	fast_fall_button.set_pressed_no_signal(fighter.fast_falling)
	hover_button.set_pressed_no_signal(fighter.hovering)
	if fast_fall_button.pressed and hover_button.pressed:
		fast_fall_button.set_pressed_no_signal(false)
#	end_hover_button.hide()
#	end_hover_button.set_pressed_no_signal(false)
	if fighter.can_hover() or fighter.hovering:
		hover_button.show()
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
	}
	return extra
