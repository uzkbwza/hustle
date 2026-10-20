extends Window


func _ready():
	var alt_layout_text = ("desktop" if Global.is_mobile_device else "mobile")
	$"%ForceAltUIButton".text = "force " + alt_layout_text + " ui layout"
	
	attach_global_toggle($"%ForceAltUIButton", "force_alt_ui")
	attach_global_toggle($"%ShowBorderArtButton", "show_border_art")
	
	Global.connect("option_changed", self, "on_option_changed")
	
	UIManager.register_menu(self, _ui_elements())

func _ui_elements() -> Array:
	return [
		$"%FullscreenButton", $"%CapFramerateButton", $"%VsyncButton",
		$"%HitboxesButton", $"%ExtraInfoButton", $"%HealthCountButton",
		$"%NextTurnHudButton", $"%ShowNextTurnOnCharsButton", $"%LastMoveIndicatorButton",
		$"%ProjectileOwnersButton", $"%PlaybackHotkeysRequireWindowButton",
		$"%SpeedLinesButton", $"%TimerSoundButton", $"%ExtraFreezeFrames",
		$"%PlaybackControls", $"%EnableEmotes", $"%EnableStyleColorsButton",
		$"%EnableAurasButton", $"%EnableHitsparksButton", $"%ShowCommunityEventsButton",
		$"%ShowBorderArtButton", $"%ForceAltUIButton", $"%MusicButton",
		$"%EnableReplayBackups", $"%AutoFCButton", $"%XYPlotInvertSnapButton",
		$"%MasterSlider", $"%FXSlider", $"%UISlider", $"%MusicSlider",
		$"%CustomName", $"%CustomNameReset", $"%NameHueSlider",
		$"%NameSaturationSlider", $"%NameColorReset",
		$"%ModToggle", $"%OptionsBackButton",
	]



func attach_global_toggle(node :Node, option :String):
	node.connect("toggled", self, "set_global_setting", [option])
	node.set_pressed_no_signal(Global.get(option))



func show():
	.show()
	$"%PlaybackControls".pressed = Global.show_playback_controls



func on_setting_changed(option = "", value = null):
	match option:
		"force_alt_ui":
			$"%ForceAltUIButton".set_pressed_no_signal(value)
		"no_border_art":
			$"%NoBorderArtButton".set_pressed_no_signal(value)



func set_global_setting(value, option):
	Global.set(option, value)
