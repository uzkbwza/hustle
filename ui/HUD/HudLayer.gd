extends CanvasLayer

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
	
	$"%P1ShowStyle".set_pressed_no_signal(true)
	$"%P2ShowStyle".set_pressed_no_signal(true)
	
	
	game.connect("game_won", self, "on_game_won")
	pass

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

func drain_health_trail(trail, drain_value):
	if drain_value < trail.value:
		trail.value -= TRAIL_DRAIN_RATE
		if trail.value < drain_value:
			trail.value = drain_value
	else:
		trail.value = drain_value

func _physics_process(_delta):
	if is_instance_valid(game):

		drain_health_trail(p1_health_bar_trail, p1.trail_hp)
		drain_health_trail(p2_health_bar_trail, p2.trail_hp)

		p1_healthbar.value = max(p1.get_visual_hp(), 0)
		p2_healthbar.value = max(p2.get_visual_hp(), 0)
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
		else:
			p1_ghost_health_bar.value = 0
			p2_ghost_health_bar.value = 0
			p1_ghost_health_bar_trail.value = 0
			p2_ghost_health_bar_trail.value = 0
			p1_ghost_health_bar.visible = false
			p2_ghost_health_bar.visible = false
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
			var p1_texture: Texture = p1.sprite.frames.get_frame(p1.sprite.animation, p1.sprite.frame)
			var p2_texture: Texture = p2.sprite.frames.get_frame(p2.sprite.animation, p2.sprite.frame)
			var p1_offset
			var p2_offset
			if p1_texture:
				$"%P1SuperTexture".rect_size = p1_texture.get_size() / game.camera.zoom.x
				p1_offset = (p1_texture.get_size() / 2) / game.camera.zoom.x
			if p2_texture:
				$"%P2SuperTexture".rect_size = p2_texture.get_size() / game.camera.zoom.x
				p2_offset = (p2_texture.get_size() / 2) / game.camera.zoom.x
			$"%P1SuperTexture".texture = p1_texture
			$"%P1SuperTexture".flip_h = p1.flip.scale.x < 0
			$"%P2SuperTexture".texture = p2_texture
			$"%P2SuperTexture".flip_h = p2.flip.scale.x < 0
			if p1_offset:
				$"%P1SuperTexture".rect_global_position = game.get_screen_position(1) + screen_center - p1_offset - (Vector2(0, 4) / game.camera.zoom.x)
				p1_super_effects_node.position = p1_offset
			if p2_offset:
				$"%P2SuperTexture".rect_global_position = game.get_screen_position(2) + screen_center - p2_offset - (Vector2(0, 4) / game.camera.zoom.x)
				p2_super_effects_node.position = p2_offset
		else:
			super_started = false
			$"%P1SuperTexture".visible = false
			$"%P2SuperTexture".visible = false
			for effect in p1_effects + p2_effects:
				effect.queue_free()
				p1_effects = []
				p2_effects = []
