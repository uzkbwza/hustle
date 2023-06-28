extends PlayerExtra

var current_dir = null

func _ready():
	$"%FlyDir".connect("data_changed", self, "emit_signal", ["data_changed"])
	$"%FlyEnabled".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%ArmorEnabled".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%NadeActive".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%PullEnabled".connect("pressed", self, "emit_signal", ["data_changed"])
	$"%PullEnabled".connect("pressed", $"%ArmorEnabled", "set_pressed_no_signal", [false])
	$"%ArmorEnabled".connect("pressed", $"%PullEnabled", "set_pressed_no_signal", [false])

func get_extra():
	current_dir = $"%FlyDir".get_dir()
	return {
		"fly_dir": $"%FlyDir".get_data() if visible else fighter.flying_dir,
		"fly_enabled": $"%FlyEnabled".pressed,
		"armor_enabled": $"%ArmorEnabled".pressed,
		"nade_activated": $"%NadeActive".pressed and $"%NadeActive".visible,
		"pull_enabled": $"%PullEnabled".pressed and $"%PullEnabled".visible,
	}


func show_options():
	$"%FlyDir".hide()
	$"%FlyEnabled".hide()
	$"%ArmorEnabled".hide()
	$"%NadeActive".hide()
	$"%PullEnabled".hide()
	$"%FlyDir".set_dir("Neutral")
	$"%FlyDir".facing = fighter.get_opponent_dir()
	$"%FlyDir".init()
	if current_dir:
		$"%FlyDir".set_dir(current_dir)
#	$"%FlyEnabled".set_pressed_no_signal(false)
	var nade = fighter.obj_from_name(fighter.grenade_object)
	if nade:
		if !nade.active:
			$"%NadeActive".show()
	if fighter.magnet_installed:
		$"%PullEnabled".show()
	if fighter.is_grounded():
		$"%FlyDir".hide()
		$"%FlyEnabled".hide()
	else:
		if fighter.air_movements_left > 0:
			$"%FlyDir".show()
			$"%FlyEnabled".show()
			$"%FlyEnabled".set_pressed_no_signal(fighter.fly_ticks_left > 0)
	if fighter.armor_pips > 0:
		$"%ArmorEnabled".show()
#	if fighter.current_state().state_name == "WhiffInstantCancel":
#		$"%ArmorEnabled".hide()
	return

func reset():
	if fighter.flying_dir:
		$"%FlyDir".set_dir_from_data(fighter.flying_dir)
		$"%FlyEnabled".set_pressed_no_signal(true)
	else:
		$"%FlyEnabled".set_pressed_no_signal(false)
	$"%ArmorEnabled".set_pressed_no_signal(false)
	$"%NadeActive".set_pressed_no_signal(false)
	$"%PullEnabled".set_pressed_no_signal(false)

func on_data_changed():
#	if $"%ArmorEnabled".pressed and $"%PullEnabled".pressed:
#		$"%PullEnabled".set_pressed_no_signal(false)
	pass
