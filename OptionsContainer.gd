extends Window


func _ready():
	var alt_layout_text = ("desktop" if Global.is_mobile_device else "mobile")
	$"%ForceAltUIButton".text = "force " + alt_layout_text + " ui layout"
	$"%ForceAltUIButton".connect("toggled", self, "set_global_setting", ["force_alt_ui"])
	$"%ForceAltUIButton".set_pressed_no_signal(Global.force_alt_ui)
	
	Global.connect("setting_changed", self, "on_setting_changed")


func show():
	.show()
	$"%PlaybackControls".pressed = Global.show_playback_controls


func on_setting_changed(setting = "", value = null):
	match setting:
		"force_alt_ui":
			$"%ForceAltUIButton".set_pressed_no_signal(value)


func set_global_setting(value, setting):
	match setting:
		"force_alt_ui":
			Global.force_alt_ui = value
			print(setting, value)
