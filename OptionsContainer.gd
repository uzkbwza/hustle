extends Window


var _jump_anchors := []
var _jump_buttons := []
var _active_jump := -1


func _ready():
	var alt_layout_text = ("desktop" if Global.is_mobile_device else "mobile")
	$"%ForceAltUIButton".text = "force " + alt_layout_text + " ui layout"

	_jump_anchors = [$"%SectionDisplay", $"%SectionGameplay", $"%SectionAudio",
		$"%SectionProfile", $"%SectionHotkeys"]
	_jump_buttons = [$"%DisplayJump", $"%GameplayJump", $"%AudioJump",
		$"%ProfileJump", $"%HotkeysJump"]
	for i in range(_jump_buttons.size()):
		_jump_buttons[i].connect("pressed", self, "_on_jump_pressed", [i])
		_jump_buttons[i].add_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	
	attach_global_toggle($"%ForceAltUIButton", "force_alt_ui")
	attach_global_toggle($"%ShowBootUIButton", "show_boot_ui")
	attach_global_toggle($"%ShowBorderArtButton", "show_border_art")
	attach_global_toggle($"%AutoClearParticlesButton", "auto_clear_particles")
	
	Global.connect("option_changed", self, "on_setting_changed")
	
	UIManager.register_menu(self, _ui_elements())

func _process(_delta) -> void:
	if not visible or _jump_buttons.empty():
		return
	var scroll = $"%OptionsScroll"
	var y = scroll.scroll_vertical + 12
	var index = 0
	for i in range(_jump_anchors.size()):
		if _jump_anchors[i].rect_position.y <= y:
			index = i
	var box = scroll.get_node("VBoxContainer")
	if scroll.scroll_vertical >= box.rect_size.y - scroll.rect_size.y - 2:
		for i in range(_jump_anchors.size()):
			if _jump_anchors[i].rect_position.y < scroll.scroll_vertical + scroll.rect_size.y:
				index = i
	if index == _active_jump:
		return
	if _active_jump >= 0:
		_jump_buttons[_active_jump].add_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	_active_jump = index
	_jump_buttons[index].add_color_override("font_color", Color(0.396078, 0.901961, 1, 1))


func _on_jump_pressed(index: int) -> void:
	if index < 0 or index >= _jump_anchors.size():
		return
	var scroll = $"%OptionsScroll"
	scroll.scroll_vertical = max(0, int(_jump_anchors[index].rect_position.y) - 8)


func _ui_elements() -> Array:
	return [
		$"%DisplayJump", $"%GameplayJump", $"%AudioJump", $"%HotkeysJump", $"%ProfileJump",
		$"%FullscreenButton", $"%ShowBootUIButton", $"%CapFramerateButton", $"%VsyncButton",
		$"%HitboxesButton", $"%ExtraInfoButton", $"%HealthCountButton",
		$"%NextTurnHudButton", $"%ShowNextTurnOnCharsButton", $"%LastMoveIndicatorButton",
		$"%ProjectileOwnersButton", $"%PlaybackHotkeysRequireWindowButton",
		$"%SpeedLinesButton", $"%TimerSoundButton", $"%ExtraFreezeFrames",
		$"%AutoClearParticlesButton",
		$"%PlaybackControls", $"%EnableEmotes", $"%EnableStyleColorsButton",
		$"%EnableAurasButton", $"%EnableHitsparksButton", $"%ShowCommunityEventsButton",
		$"%ShowSelectionArtButton", $"%ShowBorderArtButton", $"%ForceAltUIButton",
		$"%TouchReadoutButton", $"%TouchReadoutSizeSlider",
		$"%MusicButton",
		$"%EnableReplayBackups", $"%AutoFCButton", $"%XYPlotInvertSnapButton",
		$"%QuickCastHSliderButton", $"%QuickCastXYPlotButton",
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
		"show_boot_ui":
			$"%ShowBootUIButton".set_pressed_no_signal(value)
		"no_border_art":
			$"%NoBorderArtButton".set_pressed_no_signal(value)



func set_global_setting(value, option):
	Global.set(option, value)
