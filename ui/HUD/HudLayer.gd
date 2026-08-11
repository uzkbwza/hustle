extends CanvasLayer

# Same color-replacement shader the character sprite uses, so the HUD
# portrait can be recolored with a player's style palette.
const CHAR_SHADER = preload("res://characters/BaseChar.gdshader")

var game: Game

onready var p1_healthbar = $"%P1HealthBar"
onready var p2_healthbar = $"%P2HealthBar"

onready var p1_health_bar_trail = $"%P1HealthBarTrail"
onready var p2_health_bar_trail = $"%P2HealthBarTrail"

onready var p1_burst_meter = $"%P1BurstMeter"
onready var p2_burst_meter = $"%P2BurstMeter"

onready var p1_super_meter = $"%P1SuperMeter"
onready var p2_super_meter = $"%P2SuperMeter"

onready var active_p1_super_meter = $"%ActiveP1SuperMeter"
onready var active_p2_super_meter = $"%ActiveP2SuperMeter"

onready var p1_num_supers = $"%P1NumSupers"
onready var p2_num_supers = $"%P2NumSupers"

onready var p1_combo_counter = $"%P1ComboCounter"
onready var p2_combo_counter = $"%P2ComboCounter"

onready var p1_air_option_display = $"%P1AirMovementDisplay"
onready var p2_air_option_display = $"%P2AirMovementDisplay"

onready var p1_super_effects_node = $"%P1SuperEffectsNode"
onready var p2_super_effects_node = $"%P2SuperEffectsNode"

onready var p1_ghost_health_bar = $"%P1GhostHealthBar"
onready var p1_ghost_health_bar_trail = $"%P1GhostHealthBarTrail"

onready var p2_ghost_health_bar = $"%P2GhostHealthBar"
onready var p2_ghost_health_bar_trail = $"%P2GhostHealthBarTrail"

onready var p1_sadness_label = $"%P1SadnessLabel"
onready var p2_sadness_label = $"%P2SadnessLabel"

onready var p1_brace_label = $"%P1BraceLabel"
onready var p2_brace_label = $"%P2BraceLabel"

onready var extra_info_container = $"%ExtraInfoContainer"
onready var extra_info_label_1 = $"%ExtraInfoLabel1"
onready var extra_info_label_2 = $"%ExtraInfoLabel2"
onready var active_p1_initiative = $"%ActiveP1Initiative"
onready var active_p2_initiative = $"%ActiveP2Initiative"

onready var action_buttons = $"%ActionButtons"
onready var p1_action_buttons = $"%P1ActionButtons"
onready var p2_action_buttons = $"%P2ActionButtons"

onready var p1_air_movement_label = $"%P1AirMovementLabel"
onready var p2_air_movement_label = $"%P2AirMovementLabel"


const TRAIL_DRAIN_RATE = 25

var p1: Fighter
var p2: Fighter

var super_started = false

var p1_effects = []
var p2_effects = []

var p1_prev_super = 0
var p2_prev_super = 0

# Last hp_pct we wrote to Steam lobby member data for the local fighter,
# and the os-msec timestamp it was written at. Together they cap writes
# to "when the integer percent changes AND at least HP_PUBLISH_MIN_INTERVAL_MS
# has elapsed" so a heavy combo that flips several percents per frame
# doesn't spam lobby_data_update on every client.
var _last_published_hp_pct := -1
var _last_hp_publish_msec := 0
const HP_PUBLISH_MIN_INTERVAL_MS = 3000

func _ready():
	hide()
	$"%WinLabel".hide()



func init(game):
	show()
	self.game = game
	$"%GameUI".show()
	$"%WinLabel".hide()
	p1 = game.get_player(1)
	p2 = game.get_player(2)
	extra_info_label_1.fighter = p1
	extra_info_label_2.fighter = p2
	p1_air_option_display.fighter = p1
	p2_air_option_display.fighter = p2
	$"%P1Portrait".texture = p1.character_portrait
	$"%P2Portrait".texture = p2.character_portrait
	p1_healthbar.max_value = p1.MAX_HEALTH
	p2_healthbar.max_value = p2.MAX_HEALTH
	p2_health_bar_trail.max_value = p2.MAX_HEALTH
	p1_health_bar_trail.max_value = p1.MAX_HEALTH
	p1_health_bar_trail.value = p1.MAX_HEALTH
	p2_health_bar_trail.value = p2.MAX_HEALTH
	$"%P1FeintDisplay".fighter = p1
	$"%P2FeintDisplay".fighter = p2
	p1_ghost_health_bar_trail.max_value = p1.MAX_HEALTH
	p2_ghost_health_bar_trail.max_value = p2.MAX_HEALTH
	p1_ghost_health_bar_trail.value = p1.MAX_HEALTH
	p2_ghost_health_bar_trail.value = p2.MAX_HEALTH
	
	p1_ghost_health_bar.max_value = p1.MAX_HEALTH
	p2_ghost_health_bar.max_value = p2.MAX_HEALTH
	
	p1_super_meter.max_value = p1.MAX_SUPER_METER
	p2_super_meter.max_value = p2.MAX_SUPER_METER
	
	active_p1_super_meter.max_value = p1.MAX_SUPER_METER
	active_p2_super_meter.max_value = p2.MAX_SUPER_METER
	
	p1_burst_meter.fighter = p1
	p2_burst_meter.fighter = p2
	
	p1_air_movement_label.text = p1.air_option_bar_name
	p2_air_movement_label.text = p2.air_option_bar_name
	

	if Network.multiplayer_active and !SteamLobby.SPECTATING:
		$"%P1Username".text = Network.pid_to_username(1)
		$"%P2Username".text = Network.pid_to_username(2)
	elif game.match_data.has("user_data"):
		if game.match_data.user_data.has("p1"):
			$"%P1Username".text = game.match_data.user_data.p1
		if game.match_data.user_data.has("p2"):
			$"%P2Username".text = game.match_data.user_data.p2
	# Personalization name-color: in Steam matches, each side's color comes
	# from that side's published lobby member data so both fighters render
	# in their own picked color (including for spectators). In legacy MP /
	# SP / replay there's no broadcast channel, so just color the local
	# user's side from Global.
	$"%P1Username".remove_color_override("font_color")
	$"%P2Username".remove_color_override("font_color")
	# Saved replays bring their own color snapshot in user_data — that's the
	# source of truth for replay playback (live lobby data may not exist
	# anymore). Prefer it over the live lookup, fall back to live for matches
	# where it wasn't recorded (older replays).
	var ud = game.match_data.get("user_data", {}) if game.match_data else {}
	var p1_color = null
	var p2_color = null
	if ud.get("p1_color") is String and ud.p1_color != "":
		p1_color = Color("#" + ud.p1_color)
	if ud.get("p2_color") is String and ud.p2_color != "":
		p2_color = Color("#" + ud.p2_color)
	if p1_color == null or p2_color == null:
		if Network.steam:
			var p1_steam = SteamLobby.steam_id_for_match_side(1)
			var p2_steam = SteamLobby.steam_id_for_match_side(2)
			if p1_color == null and p1_steam != 0:
				p1_color = Global.get_remote_name_color(p1_steam)
			if p2_color == null and p2_steam != 0:
				p2_color = Global.get_remote_name_color(p2_steam)
		elif !SteamLobby.SPECTATING and Global.has_name_color():
			# Network.player_id defaults to 2 and is only set in actual MP
			# setup paths. Treat non-multiplayer as "you are P1" so vs-CPU
			# shows the user's color on their character.
			var my_side = Network.player_id if Network.multiplayer_active else 1
			if my_side == 1 and p1_color == null:
				p1_color = Global.get_name_color()
			elif my_side == 2 and p2_color == null:
				p2_color = Global.get_name_color()
	if p1_color != null:
		$"%P1Username".add_color_override("font_color", p1_color)
	if p2_color != null:
		$"%P2Username".add_color_override("font_color", p2_color)
	
	$"%P1ShowStyle".set_pressed_no_signal(true)
	$"%P2ShowStyle".set_pressed_no_signal(true)
	refresh_portrait_style(1)
	refresh_portrait_style(2)


	game.connect("game_won", self, "on_game_won")
	pass

# Recolor a player's HUD portrait with their style's palette (colors only —
# no auras / outline effects beyond what the palette defines). Mirrors the
# CSS CharacterDisplay path: the source replacement colors come from the
# character itself, the target colors from the applied style. The portrait
# always runs through the color-replacement shader (no modulate tint) — when
# the style is off / null / disabled it falls back to the engine's default
# per-player body color (P1_COLOR / P2_COLOR) at the shader level.
func refresh_portrait_style(player_id):
	if not is_instance_valid(game):
		return
	var portrait = $"%P1Portrait" if player_id == 1 else $"%P2Portrait"
	var show_btn = $"%P1ShowStyle" if player_id == 1 else $"%P2ShowStyle"
	var player = game.get_player(player_id)
	if player == null:
		return
	# All coloring happens in the shader now — clear any modulate tint baked
	# into the scene so it doesn't double up on the shader color.
	portrait.modulate = Color.white
	portrait.self_modulate = Color.white
	var mat = portrait.material
	if not (mat is ShaderMaterial):
		mat = ShaderMaterial.new()
		mat.shader = CHAR_SHADER
		portrait.material = mat
	# Source magenta keys to replace come from the character; reset the base
	# params before applying either the style or the default color.
	mat.set_shader_param("extra_replace_color_1", player.extra_color_1)
	mat.set_shader_param("extra_replace_color_2", player.extra_color_2)
	mat.set_shader_param("use_outline", false)
	mat.set_shader_param("use_extra_color_1", false)
	mat.set_shader_param("use_extra_color_2", false)
	var style = player.applied_style
	if show_btn.pressed and style != null and Global.enable_custom_colors:
		mat.set_shader_param("color", Color.white)
		Custom.apply_style_to_material(style, mat, true)
	else:
		# Default per-player body color (same constants the character sprite
		# uses in reset_color), applied at the shader level instead of via a
		# modulate tint.
		mat.set_shader_param("color", player.P1_COLOR if player_id == 1 else player.P2_COLOR)

func healthbar_armor_effect(player, healthbar: TextureProgress, no_armor_image, armor_image, projectile_armor_image):
	if player.has_armor():
		if healthbar.texture_progress != armor_image:
			healthbar.texture_progress = armor_image
	elif player.has_projectile_armor():
		if healthbar.texture_progress != projectile_armor_image:
			healthbar.texture_progress = projectile_armor_image
	else:
		if healthbar.texture_progress != no_armor_image:
			healthbar.texture_progress = no_armor_image

func on_game_won(winner):
	$"HudAnimationPlayer".play("game_won")
	if winner == 0:
		$"%WinLabel".text = "DRAW"
	else:
		$"%WinLabel".text = "P" + str(winner) + " WIN"
	SteamHustle.record_winner(winner)

func super_speed_scale(ticks):
	return 15 * (15 / float(ticks))

# Publish the local fighter's current hp percent (0..100) to Steam lobby
# member data so other lobby members can render it on the LobbyMatch panel.
# Only the local fighter (not spectators, not other-side players) writes;
# skipped entirely outside steam multiplayer. Dedup on the integer percent
# keeps writes down to "once per visible hp change" instead of every tick.
func _publish_local_hp_pct():
	if not Network.steam or not Network.multiplayer_active or SteamLobby.SPECTATING:
		return
	if SteamLobby.LOBBY_ID == 0:
		return
	# Don't broadcast during post-game replay — the live match is over,
	# spectators in the lobby would see HP rewind/flicker as the replay
	# plays back.
	if is_instance_valid(game) and game.is_in_replay:
		return
	var local_fighter
	if Network.player_id == 1:
		local_fighter = p1
	elif Network.player_id == 2:
		local_fighter = p2
	else:
		return
	if local_fighter == null or local_fighter.MAX_HEALTH <= 0:
		return
	var pct = int(max(local_fighter.get_visual_hp(), 0) * 100 / local_fighter.MAX_HEALTH)
	if pct == _last_published_hp_pct:
		return
	var now = OS.get_ticks_msec()
	if now - _last_hp_publish_msec < HP_PUBLISH_MIN_INTERVAL_MS:
		return
	_last_published_hp_pct = pct
	_last_hp_publish_msec = now
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "hp_pct", str(pct))

func drain_health_trail(trail, drain_value):
	if drain_value < trail.value:
		trail.value -= TRAIL_DRAIN_RATE
		if trail.value < drain_value:
			trail.value = drain_value
	else:
		trail.value = drain_value

# Copy the ghost's "Ready in Xf" / "Interrupt in Xf" / "Hit @ Xf" floating
# labels into fixed HUD spots, and (independently) hide the same text on the
# characters themselves via modulate so it doesn't obscure the prediction.
# Both are user-toggleable; default is HUD on, character labels on.
func _sync_next_turn_info(p1_ghost, p2_ghost):
	if Global.show_next_turn_info_hud:
		_mirror_next_turn_label($"%P1NextTurnReadyLabel", p1_ghost.actionable_label)
		_mirror_next_turn_label($"%P1NextTurnHitLabel", p1_ghost.hit_frame_label)
		_mirror_next_turn_label($"%P2NextTurnReadyLabel", p2_ghost.actionable_label)
		_mirror_next_turn_label($"%P2NextTurnHitLabel", p2_ghost.hit_frame_label)
	else:
		$"%P1NextTurnReadyLabel".text = ""
		$"%P1NextTurnHitLabel".text = ""
		$"%P2NextTurnReadyLabel".text = ""
		$"%P2NextTurnHitLabel".text = ""
	# Hide on characters via modulate (not .visible) so ghost_tick's visibility
	# gating in game.gd stays untouched — the label still counts as "shown",
	# just renders at alpha 0.
	var char_alpha = 1.0 if Global.show_next_turn_info_on_chars else 0.0
	p1_ghost.actionable_label.modulate.a = char_alpha
	p1_ghost.hit_frame_label.modulate.a = char_alpha
	p2_ghost.actionable_label.modulate.a = char_alpha
	p2_ghost.hit_frame_label.modulate.a = char_alpha

func _mirror_next_turn_label(hud_label, char_label):
	if not is_instance_valid(char_label) or not char_label.visible:
		hud_label.text = ""
		return
	# Char labels use "Ready\nin Xf" multi-line; flatten for the narrow HUD spot.
	hud_label.text = char_label.text.replace("\n", " ")

func _physics_process(_delta):
	if is_instance_valid(game):

		drain_health_trail(p1_health_bar_trail, p1.trail_hp)
		drain_health_trail(p2_health_bar_trail, p2.trail_hp)

		p1_healthbar.value = max(p1.get_visual_hp(), 0)
		p2_healthbar.value = max(p2.get_visual_hp(), 0)
		_publish_local_hp_pct()
		if p2_prev_super < p2.supers_available:
			p2_super_meter.value = p2.MAX_SUPER_METER
			active_p2_super_meter.value = p2.MAX_SUPER_METER
		else:
			p2_super_meter.value = p2.super_meter
			active_p2_super_meter.value = p2.super_meter
		if p1_prev_super < p1.supers_available:
			p1_super_meter.value = p1.MAX_SUPER_METER
			active_p1_super_meter.value = p1.MAX_SUPER_METER
		else:
			p1_super_meter.value = p1.super_meter
			active_p1_super_meter.value = p1.super_meter
		p1_prev_super = p1.supers_available
		p2_prev_super = p2.supers_available
		p1_num_supers.texture.current_frame = clamp(p1.supers_available, 0, 9)
		p2_num_supers.texture.current_frame = clamp(p2.supers_available, 0, 9)
		p1_combo_counter.set_combo(str(p1.visible_combo_count))
		p2_combo_counter.set_combo(str(p2.visible_combo_count))

		if is_instance_valid(game.ghost_game):
			p1_ghost_health_bar.visible = true
			p2_ghost_health_bar.visible = true
			var gg: Game = game.ghost_game
			var p1_ghost = gg.get_player(1)
			var p2_ghost = gg.get_player(2)
			p1_ghost_health_bar.value = max(p1_ghost.get_visual_hp(), 0)
			p2_ghost_health_bar.value = max(p2_ghost.get_visual_hp(), 0)
			drain_health_trail(p1_ghost_health_bar_trail, p1_ghost.trail_hp)
			drain_health_trail(p2_ghost_health_bar_trail, p2_ghost.trail_hp)
			_sync_next_turn_info(p1_ghost, p2_ghost)
		else:
			p1_ghost_health_bar.value = 0
			p2_ghost_health_bar.value = 0
			p1_ghost_health_bar_trail.value = 0
			p2_ghost_health_bar_trail.value = 0
			p1_ghost_health_bar.visible = false
			p2_ghost_health_bar.visible = false
			# No prediction in flight — wipe the HUD mirrors so stale text from
			# the last prediction doesn't linger.
			$"%P1NextTurnReadyLabel".text = ""
			$"%P1NextTurnHitLabel".text = ""
			$"%P2NextTurnReadyLabel".text = ""
			$"%P2NextTurnHitLabel".text = ""
#
		healthbar_armor_effect(p1, p1_healthbar, preload("res://ui/healthbar3.png"), preload("res://ui/healthbar3_armor.png"), preload("res://ui/healthbar_projectile_armor.png"))
		healthbar_armor_effect(p1, p1_ghost_health_bar, preload("res://ui/healthbar3.png"), preload("res://ui/healthbar3_armor.png"), preload("res://ui/healthbar_projectile_armor.png"))
		healthbar_armor_effect(p2, p2_healthbar, preload("res://ui/healthbar_p2_3.png"), preload("res://ui/healthbar_p2_3_armor.png"), preload("res://ui/healthbar_projectile_armor_p2.png"))
		healthbar_armor_effect(p2, p2_ghost_health_bar, preload("res://ui/healthbar_p2_3.png"), preload("res://ui/healthbar_p2_3_armor.png"), preload("res://ui/healthbar_projectile_armor_p2.png"))

		$"%P1ShowStyle".visible = game.game_paused and p1.applied_style != null
		$"%P2ShowStyle".visible = game.game_paused and p2.applied_style != null
#
		if !ReplayManager.playback or p1.visible_combo_count > 1:
			$"%P1DmgLabel".text = str(p1.combo_damage * 10) + " DMG"
		else:
			$"%P1DmgLabel".text = ""
		$"%P1DmgLabel".visible = p1.combo_damage > 0
		if !ReplayManager.playback or p2.visible_combo_count > 1:
			$"%P2DmgLabel".text = str(p2.combo_damage * 10) + " DMG"
		else:
			$"%P2DmgLabel".text = ""
		$"%P2DmgLabel".visible = p2.combo_damage > 0

		$"%P1HitLabel".visible = p1.visible_combo_count >= 2
		$"%P2HitLabel".visible = p2.visible_combo_count >= 2
	
		$"%Timer".text = str(game.get_ticks_left())
		$"%SuperDim".visible = game.super_active and !game.parry_freeze
		$"%P1SuperTexture".visible = game.p1_super
		$"%P2SuperTexture".visible = game.p2_super
		p1_super_meter.texture_progress = preload("res://ui/super_bar3.png") if p1.supers_available < 1 else preload("res://ui/super_ready.tres")
		p2_super_meter.texture_progress = preload("res://ui/super_bar3.png") if p2.supers_available < 1 else preload("res://ui/super_ready.tres")

		active_p1_super_meter.texture_progress = preload("res://ui/super_bar_small3.png") if p1.supers_available < 1 else preload("res://ui/super_ready_small.tres")
		active_p2_super_meter.texture_progress = preload("res://ui/super_bar_small3.png") if p2.supers_available < 1 else preload("res://ui/super_ready_small.tres")


		$"%P1CounterLabel".visible = p2.current_state() is CharacterHurtState and p2.current_state().counter and (game.game_paused or (game.real_tick / 2) % 2 == 0)
		$"%P2CounterLabel".visible = p1.current_state() is CharacterHurtState and p1.current_state().counter and (game.game_paused or (game.real_tick / 2) % 2 == 0)
		$"%P1GuardBreakLabel".visible = p2.guard_broken_this_turn and (game.game_paused or (game.real_tick / 2) % 2 == 0)
		$"%P2GuardBreakLabel".visible = p1.guard_broken_this_turn and (game.game_paused or (game.real_tick / 2) % 2 == 0)
		p1_brace_label.visible = p1.current_state() is CounterAttack and p1.current_state().bracing and (game.game_paused or ((game.real_tick / 2) + 1) % 2 == 0)
		p2_brace_label.visible = p2.current_state() is CounterAttack and p2.current_state().bracing  and (game.game_paused or ((game.real_tick / 2) + 1) % 2 == 0)

		var p1_paused_initiative = game.game_paused and !p1.check_initiative() and !p1.busy_interrupt
		var p2_paused_initiative = game.game_paused and !p2.check_initiative() and !p2.busy_interrupt
		$"%P1AdvantageLabel".visible = (p1.initiative and p1.current_state().initiative_effect)
		$"%P2AdvantageLabel".visible = (p2.initiative and p2.current_state().initiative_effect)
		$"%P1AdvantageLabel".modulate.a = 1.0 - p1.current_state().current_tick * 0.1
		$"%P2AdvantageLabel".modulate.a = 1.0 - p2.current_state().current_tick * 0.1
		active_p1_initiative.visible = p1_paused_initiative and action_buttons.visible and p1_action_buttons.visible
		active_p2_initiative.visible = p2_paused_initiative and action_buttons.visible and p2_action_buttons.visible

		p1_sadness_label.visible = p1.penalty > p1.PENALTY_MIN_DISPLAY
		p2_sadness_label.visible = p2.penalty > p2.PENALTY_MIN_DISPLAY
		
		if p1.penalty_ticks <= 0:
			p1_sadness_label.visible = p1_sadness_label.visible and Utils.wave(0, 1, 0.25) < 0.50
			p1_sadness_label.text = "SAD!"
			p1_sadness_label.modulate = Color("ff333d")
		else:
			p1_sadness_label.visible = true
			p1_sadness_label.text = "SADNESS"
			p1_sadness_label.modulate = Color("d440b6")
		
		if p2.penalty_ticks <= 0:
			p2_sadness_label.visible = p2_sadness_label.visible and Utils.wave(0, 1, 0.25) < 0.50
			p2_sadness_label.text = "SAD!"
			p2_sadness_label.modulate = Color("ff333d")
		else:
			p2_sadness_label.visible = true
			p2_sadness_label.text = "SADNESS"
			p2_sadness_label.modulate = Color("d440b6")
	
		if game.super_active and !game.parry_freeze:
			if !super_started:
				var fx_scene = preload("res://fx/superparticle.tscn") if !game.prediction_effect else preload("res://fx/predictparticle.tscn")
				if game.p1_super:
					var fx = fx_scene.instance()
					fx.set_speed_scale(super_speed_scale(game.super_freeze_ticks))
					p1_super_effects_node.call_deferred("add_child", fx)
					p1_effects.append(fx)
					
				if game.p2_super:
					var fx = fx_scene.instance()
					fx.set_speed_scale(super_speed_scale(game.super_freeze_ticks))
					p2_super_effects_node.call_deferred("add_child", fx)
					p1_effects.append(fx)
				super_started = true
			$"%P1SuperTexture".set_material(p1.get_material())
			$"%P2SuperTexture".set_material(p2.get_material())
			var screen_center = game.get_viewport_rect().size/2
			var cam_screen_center = game.camera.get_camera_screen_center()
			var zoom = game.camera.zoom.x
			var p1_texture: Texture = p1.sprite.frames.get_frame(p1.sprite.animation, p1.sprite.frame)
			var p2_texture: Texture = p2.sprite.frames.get_frame(p2.sprite.animation, p2.sprite.frame)
			$"%P1SuperTexture".texture = p1_texture
			$"%P1SuperTexture".flip_h = p1.flip.scale.x < 0
			$"%P2SuperTexture".texture = p2_texture
			$"%P2SuperTexture".flip_h = p2.flip.scale.x < 0
			# Place each overlay on its sprite's actual rendered center
			# (player.position + sprite.offset, x-flipped for facing) and size
			# it to match the sprite's rendered scale (1/camera.zoom).
			if p1_texture:
				var p1_size = p1_texture.get_size() / zoom
				var p1_world = p1.position + Vector2(p1.sprite.offset.x * sign(p1.flip.scale.x), p1.sprite.offset.y)
				var p1_screen = (p1_world - cam_screen_center) / zoom + screen_center
				$"%P1SuperTexture".rect_size = p1_size
				$"%P1SuperTexture".rect_global_position = p1_screen - p1_size / 2
				p1_super_effects_node.position = p1_size / 2
			if p2_texture:
				var p2_size = p2_texture.get_size() / zoom
				var p2_world = p2.position + Vector2(p2.sprite.offset.x * sign(p2.flip.scale.x), p2.sprite.offset.y)
				var p2_screen = (p2_world - cam_screen_center) / zoom + screen_center
				$"%P2SuperTexture".rect_size = p2_size
				$"%P2SuperTexture".rect_global_position = p2_screen - p2_size / 2
				p2_super_effects_node.position = p2_size / 2
		else:
			super_started = false
			$"%P1SuperTexture".visible = false
			$"%P2SuperTexture".visible = false
			for effect in p1_effects + p2_effects:
				effect.queue_free()
				p1_effects = []
				p2_effects = []
				
		if $"%P1HealthBar".is_visible_in_tree():
			var viz = Global.show_health_count
			var p1c = $"%P1HpCount"
			var p2c = $"%P2HpCount"
			p1c.visible = viz
			p2c.visible = viz
			if viz:
				p1c.text = str(p1.hp * 10) + " / " + str(p1.MAX_HEALTH * 10) 
				p2c.text = str(p2.hp * 10) + " / " + str(p2.MAX_HEALTH * 10) 
			
