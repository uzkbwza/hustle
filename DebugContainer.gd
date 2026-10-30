extends HBoxContainer

var steam_button

func _ready():
	if not OS.is_debug_build():
		return
	steam_button = Button.new()
	steam_button.text = "connect steam"
	steam_button.rect_min_size = Vector2(92, 16)
	steam_button.size_flags_vertical = 0
	steam_button.theme = load("res://theme.tres")
	steam_button.hint_tooltip = "Retry Steamworks init (Ctrl+D shows this panel)"
	steam_button.connect("pressed", self, "_on_connect_steam_pressed")
	add_child(steam_button)

func _process(_delta):
	if steam_button == null:
		return
	var main = get_tree().current_scene
	var in_match = main != null and "game" in main and is_instance_valid(main.game)
	steam_button.visible = not in_match

func _on_connect_steam_pressed():
	var connected = SteamHustle.connect_steam()
	if connected:
		steam_button.text = "steam ok"
	else:
		steam_button.text = "steam failed (%s)" % str(SteamHustle.LAST_INIT_STATUS)
	print("connect_steam -> ", connected, " status=", SteamHustle.LAST_INIT_STATUS)

func _input(event):
	if event.is_action_pressed("open_debug_panel") and OS.is_debug_build():
		visible = !visible
