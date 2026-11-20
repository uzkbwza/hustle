extends Panel

signal challenge_pressed()
signal replay_challenge_pressed(member)
signal avatar_loaded()

#const MEMBER_MIN_SIZE = 30
#const OWNER_MIN_SIZE = 44
onready var owner_actions = $OwnerActions

var member

# Avatar hover overlay + state so the border can stay shown while the
# user-actions popup is open even if the mouse moves off the icon.
var _avatar_border: Panel
var _avatar_mouse_over := false
# Last status string applied to the self-row challenge button. Tracked so
# _refresh_self_button can short-circuit when nothing changed — every
# `add_stylebox_override` call resets the button's hover state visually,
# and lobby_data_update fires often (every member-data write in the lobby,
# including the owner's match_settings_json publishing).
var _last_self_button_status := ""

func _ready():
	Steam.connect("avatar_loaded", self, "_loaded_Avatar")
	$"%ChallengeButton".connect("pressed", self, "on_challenge_pressed")
	$"%ReplayChallengeButton".connect("pressed", self, "on_replay_challenge_pressed")
	# Make the avatar clickable so the lobby owner can right- or left-click
	# another user's portrait to surface ownership transfer.
	$"%AvatarIcon".connect("gui_input", self, "_on_avatar_gui_input")
	$"%AvatarIcon".mouse_filter = Control.MOUSE_FILTER_STOP
	$"%AvatarIcon".mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# White inset border on hover so the avatar reads as clickable. Built as
	# a transparent-fill Panel child that overlays the texture. Visibility
	# is driven by either the mouse being over the icon OR the action
	# popup being open — so the border keeps reading the avatar as "active"
	# while the menu is up, even if the cursor moves down to the menu.
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 1
	border_style.border_width_top = 1
	border_style.border_width_right = 1
	border_style.border_width_bottom = 1
	border_style.border_color = Color.white
	_avatar_border = Panel.new()
	_avatar_border.name = "HoverBorder"
	_avatar_border.anchor_right = 1.0
	_avatar_border.anchor_bottom = 1.0
	_avatar_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_border.add_stylebox_override("panel", border_style)
	_avatar_border.hide()
	$"%AvatarIcon".add_child(_avatar_border)
	$"%AvatarIcon".connect("mouse_entered", self, "_on_avatar_mouse_entered")
	$"%AvatarIcon".connect("mouse_exited", self, "_on_avatar_mouse_exited")
	# Re-render the self row whenever lobby member data changes — covers the
	# return-from-spectating / match-exit transitions where the row's status
	# label and toggle state should snap to the new value without waiting for
	# the next full member-list refresh.
	SteamLobby.connect("lobby_data_update", self, "_on_lobby_data_update")
	# Block/unblock from the owner popup needs to flip this row's button
	# immediately, not wait for a status change.
	SteamLobby.connect("user_block_state_changed", self, "_on_user_block_state_changed")
	# When the shared user-actions popup closes, refresh the avatar border —
	# without this the row that opened it keeps drawing the "popup open"
	# border until the next mouse_entered/exited.
	SteamLobby.connect("lobby_user_popup_hidden", self, "_on_lobby_user_popup_hidden")

func init(member):
#	if $"%AvatarIcon".texture == null:
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, member.steam_id)
	$"%Username".text = member.steam_name
	_refresh_block_mute_prefix(member.steam_id)
	# Apply any user's published Personalization name color (broadcast via
	# Steam lobby member data) so every row tints with its owner's color.
	var custom = Global.get_remote_name_color(member.steam_id)
	if custom != null:
		$"%Username".add_color_override("font_color", custom)
	else:
		$"%Username".remove_color_override("font_color")
	self.member = member
	$"%OwnerIcon".visible = false
	$"%ChallengeButton".hide()
	$"%ReplayChallengeButton".hide()
	$"%ChallengeButton".disabled = false
	$"%ChallengeButton".text = "challenge"
	if Steam.getLobbyOwner(SteamLobby.LOBBY_ID) == member.steam_id:
		$"%OwnerIcon".visible = true
	var status = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, member.steam_id, "status")
	var status_label = _format_status_label(member.steam_id, status)
	if SteamHustle.STEAM_ID != member.steam_id:
		# Other user — show the challenge button (and optionally the replay
		# challenge button). If they're not idle, demote to a disabled status
		# badge so the row reads as "unavailable".
		$"%ChallengeButton".show()
		if SteamLobby.LOBBY_REPLAY_CHALLENGE_ENABLED:
			$"%ReplayChallengeButton".show()
		else:
			$"%ChallengeButton".margin_right = 92
		if status != "idle":
			$"%ChallengeButton".disabled = true
			$"%ReplayChallengeButton".hide()
			$"%ChallengeButton".margin_right = 92
			$"%ChallengeButton".text = status_label
		# Blocked overrides any status. Show a dark-red "blocked" badge so the
		# user can't accidentally try to challenge someone they've blocked.
		if SteamLobby.is_blocked(member.steam_id):
			$"%ChallengeButton".disabled = true
			$"%ReplayChallengeButton".hide()
			$"%ChallengeButton".margin_right = 92
			$"%ChallengeButton".text = "blocked"
			_apply_blocked_bg($"%ChallengeButton")
		else:
			_apply_status_bg($"%ChallengeButton", "")
	else:
		# Self row — the button slot doubles as a live idle↔busy toggle
		# (when the match flow doesn't own the status). Text + tint reflect
		# the current actual Steam status so any drift between
		# Global.lobby_busy_mode and the lobby member data is visible.
		$"%ChallengeButton".show()
		$"%ChallengeButton".margin_right = 92
		# init() resets the text/disabled above, so force the self button to
		# repaint instead of letting the idempotence check keep a stale label.
		_last_self_button_status = ""
		_refresh_self_button()

# Re-render the self row's status button from the current Steam member data.
# Called from init() and from lobby_data_update (e.g. after returning from
# spectating or a match ends).
func _refresh_self_button():
	if member == null or member.steam_id != SteamHustle.STEAM_ID:
		return
	# For the idle/busy split, drive the visual off Global.lobby_busy_mode
	# directly — the local preference is the source of truth and updates
	# synchronously on click. Reading getLobbyMemberData for it was racy on
	# the first toggle (Steam's local cache hadn't reflected the just-issued
	# setLobbyMemberData yet, so the button repainted with the old status).
	# Match-owned states (fighting / spectating) still come from Steam since
	# those are driven by the match flow, not the toggle.
	var steam_status = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, member.steam_id, "status")
	var display_status = steam_status
	if steam_status != "fighting" and steam_status != "spectating":
		display_status = "busy" if Global.lobby_busy_mode else "idle"
	# Idempotent — skip the stylebox/text repaint if nothing changed.
	# lobby_data_update fires for every lobby/member-data write in the
	# lobby (status flips, name_color publishes, match_settings_json
	# publishes, etc.) and re-applying styleboxes on every fire visually
	# resets the button's hover state.
	if display_status == _last_self_button_status:
		return
	_last_self_button_status = display_status
	$"%ChallengeButton".text = _format_status_label(member.steam_id, display_status)
	$"%ChallengeButton".disabled = not (display_status == "idle" or display_status == "busy")
	_apply_status_bg($"%ChallengeButton", display_status)

# Override just the button's background stylebox (not modulate on the whole
# node — that'd tint the text too). Clears the override for match-owned
# states so the theme's default disabled look applies there.
func _apply_status_bg(btn: Button, status: String):
	if status != "idle" and status != "busy":
		btn.remove_stylebox_override("normal")
		btn.remove_stylebox_override("hover")
		btn.remove_stylebox_override("pressed")
		btn.remove_stylebox_override("disabled")
		return
	var bg = StyleBoxFlat.new()
	var hover = StyleBoxFlat.new()
	var pressed = StyleBoxFlat.new()
	match status:
		"idle":
			bg.bg_color = Color("008561")
			hover.bg_color = Color("64d26b")
			pressed.bg_color = Color("000000")
		"busy":
			bg.bg_color = Color("343537")
			hover.bg_color = Color("42525c")
			pressed.bg_color = Color("000000")
	for sb in [bg, hover, pressed]:
		sb.border_width_bottom = 1
		sb.border_width_right = 1
		sb.border_color = Color.black
	btn.add_stylebox_override("normal", bg)
	btn.add_stylebox_override("hover", hover)
	btn.add_stylebox_override("pressed", pressed)

func _apply_blocked_bg(btn: Button):
	# Override `disabled` too — that's the stylebox Godot actually paints for
	# a disabled button, so without it the theme's grey disabled bg shows
	# through and the dark-red normal/hover/pressed are invisible. Match the
	# bottom + right black outline the regular button styleboxes have.
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("300505")
	sb.border_width_bottom = 1
	sb.border_width_right = 1
	sb.border_color = Color.black
	btn.add_stylebox_override("normal", sb)
	btn.add_stylebox_override("hover", sb)
	btn.add_stylebox_override("pressed", sb)
	btn.add_stylebox_override("disabled", sb)

# Add or remove a small red prefix label ([X] or [M]) inside the row's inner
# HBoxContainer, before UsernameHolder. Kept as a separate node so it can be
# colored independently of the Username label (which carries the user's name
# color).
const _PREFIX_NODE_NAME = "BlockMutePrefix"

func _refresh_block_mute_prefix(steam_id: int):
	var inner_hbox = $"HBoxContainer/VBoxContainer/HBoxContainer"
	# Sweep any existing prefix(es). Have to scan by name-prefix because Godot
	# auto-renames new siblings with a colliding name (BlockMutePrefix2 etc.)
	# when the prior one is still queue-freed-but-in-tree, which strands stale
	# copies that has_node lookups miss. Free immediately, not queue_free, so
	# the next add_child can reuse the canonical name.
	for child in inner_hbox.get_children():
		if child.name.begins_with(_PREFIX_NODE_NAME):
			inner_hbox.remove_child(child)
			child.free()
	var text = ""
	if SteamLobby.is_blocked(steam_id):
		text = "[X] "
	elif SteamLobby.is_muted(steam_id):
		text = "[M] "
	if text == "":
		return
	var lbl = Label.new()
	lbl.name = _PREFIX_NODE_NAME
	lbl.text = text
	lbl.add_color_override("font_color", Color("85001f"))
	inner_hbox.add_child(lbl)
	# Slot just after OwnerIcon (index 0) so the prefix sits immediately to
	# the left of UsernameHolder.
	inner_hbox.move_child(lbl, 1)

func _on_lobby_data_update(_a=null, _b=null, _c=null):
	# Skip when offscreen — lobby_data_update fires constantly during
	# matches from hp_pct publishes, and there's no point re-styling a
	# button no one can see.
	if not is_visible_in_tree():
		return
	_refresh_self_button()

func _on_user_block_state_changed(_steam_id=null):
	# Cheapest correct response — re-run init() to redo the status badge from
	# scratch, including the blocked override. Per-row signal so this fires
	# even when nothing else in the lobby changed.
	if member != null:
		init(member)

func _format_status_label(steam_id, status) -> String:
	if status == "fighting":
		var opp = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "opponent_id")
		if opp != "":
			return "fighting " + Steam.getFriendPersonaName(int(opp))
		return "fighting"
	elif status == "spectating":
		var spec = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "spectating_id")
		if spec != "":
			return "spectating " + Steam.getFriendPersonaName(int(spec))
		return "spectating"
	return status

#	var lobby_owner = SteamLobby.am_i_lobby_owner()
#	rect_min_size.y = MEMBER_MIN_SIZE if !lobby_owner else OWNER_MIN_SIZE
#	owner_actions.visible = lobby_owner

func update_avatar():
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, member.steam_id)

func on_challenge_pressed():
	if member == null:
		return
	# Self row — the button is a live idle↔busy toggle now. Flip the persisted
	# preference, push it to Steam, and refresh the visual state.
	if member.steam_id == SteamHustle.STEAM_ID:
		Global.lobby_busy_mode = not Global.lobby_busy_mode
		Global.save_options()
		SteamLobby.apply_busy_mode()
		_refresh_self_button()
		return
	emit_signal("challenge_pressed")
	SteamLobby.challenge_user(member)

func on_replay_challenge_pressed():
	if member:
		emit_signal("replay_challenge_pressed", member)

func _loaded_Avatar(id: int, size: int, buffer: PoolByteArray) -> void:
	if id != member.steam_id:
		return
	print("Avatar for user: "+str(id))
	print("Size: "+str(size))
	# Create the image and texture for loading
	var AVATAR = Image.new()
	var AVATAR_TEXTURE: ImageTexture = ImageTexture.new()
	AVATAR.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	# Apply it to the texture
	AVATAR_TEXTURE.create_from_image(AVATAR)
	# Set it
	$"%AvatarIcon".set_texture(AVATAR_TEXTURE)
	emit_signal("avatar_loaded")

func _on_avatar_gui_input(event: InputEvent):
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != BUTTON_LEFT:
		return
	if member == null:
		return
	# Self row no longer uses the avatar popup — the row's status button
	# directly toggles busy mode. Skip opening anything for the local user.
	if member.steam_id == SteamHustle.STEAM_ID:
		return
	_show_owner_popup()

func _on_avatar_mouse_entered():
	_avatar_mouse_over = true
	_refresh_avatar_border()

func _on_avatar_mouse_exited():
	_avatar_mouse_over = false
	_refresh_avatar_border()

# Border shows whenever the mouse is over the avatar OR the shared user-
# actions popup is currently open for THIS row's member. The popup itself
# lives on the SteamLobby autoload now (so it survives lobby refreshes), so
# we ask the autoload whether it's open for our steam_id.
func _refresh_avatar_border():
	if _avatar_border == null or member == null:
		return
	var popup_open = SteamLobby.is_lobby_user_popup_open_for(member.steam_id)
	_avatar_border.visible = _avatar_mouse_over or popup_open

func _show_owner_popup():
	var avatar_rect = $"%AvatarIcon".get_global_rect()
	var pos = avatar_rect.position + Vector2(0, avatar_rect.size.y)
	SteamLobby.show_lobby_user_popup(pos, member.steam_id)
	_refresh_avatar_border()

func _on_lobby_user_popup_hidden(_steam_id=null):
	_refresh_avatar_border()
