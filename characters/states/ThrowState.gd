extends CharacterState

class_name ThrowState

var released = false

export var _c_Throw_Data = 0
export var release = false
export var release_frame = -1
export var use_start_throw_pos = true
export var start_throw_pos_x = 0
export var start_throw_pos_y = 0
export var use_release_throw_pos = true
export var release_throw_pos_x = 0
export var release_throw_pos_y = 0

export var _c_Release_Data = 0
export var hitstun_ticks: int = 0
#export var combo_hitstun_ticks: int = -1
export var knockback: String = "1.0"
export var dir_x: String = "1.0"
export var dir_y: String = "0.0"
export var knockdown: bool = true
export var knockdown_extends_hitstun: bool = true
export var aerial_hit_state = "HurtAerial"
export var grounded_hit_state = "HurtGrounded"
export var damage = 10
export var damage_in_combo = -1
export var reverse = false
export var disable_collision = true
export var ground_bounce = true
export var screenshake_amount = 0
export var screenshake_frames = 0
export var hits_otg = false
export var increment_combo = true
export var hard_knockdown = false
export var force_grounded = false
export var air_ground_bounce = false
export var wall_slam = false
export var di_modifier = "1.0"
export var minimum_grounded_frames = -1
export var damage_proration = 0

export(Hitbox.HitHeight) var hit_height = Hitbox.HitHeight.Mid
#export var incr_combo = false
export var _c_Release_Sound = 0
export(AudioStream) var release_sfx = null
export var release_sfx_volume = -10.0
export var play_release_sfx_bass = true

export(String, MULTILINE) var misc_data = ""

var hitlag_ticks = 0
var victim_hitlag = 0
var throw = true

var release_sfx_player = null

func _enter():
	released = false

func setup_audio():
	.setup_audio()
	if release_sfx:
		release_sfx_player = VariableSound2D.new()
		add_child(release_sfx_player)
		release_sfx_player.bus = "Fx"
		release_sfx_player.stream = release_sfx
		release_sfx_player.volume_db = release_sfx_volume

func update_throw_position():
	var frame = host.get_current_sprite_frame()
	if frame in throw_positions:
		var pos = throw_positions[frame]
		host.throw_pos_x = pos.x
		host.throw_pos_y = pos.y
	elif frame in host.throw_positions:
		var pos = host.throw_positions[frame]
		host.throw_pos_x = pos.x
		host.throw_pos_y = pos.y

func _frame_0_shared():
	._frame_0_shared()
	host.opponent.change_state("Grabbed")
	if use_start_throw_pos:
		host.throw_pos_x = start_throw_pos_x
		host.throw_pos_y = start_throw_pos_y
	else:
		update_throw_position()
	var throw_pos = host.get_global_throw_pos()
	host.opponent.set_pos(throw_pos.x, throw_pos.y)

func _tick_shared():
	if current_tick == 0:
		throw = true
#		host.opponent.change_state("Grabbed")
#		host.throw_pos_x = start_throw_pos_x
#		host.throw_pos_y = start_throw_pos_y
#		var throw_pos = host.get_global_throw_pos()
#		host.opponent.set_pos(throw_pos.x, throw_pos.y)
		if reverse and !force_same_direction_as_previous_state:
			host.reverse_state = false
			host.set_facing(-host.get_facing_int())
		host.start_invulnerability()
		released = false
	._tick_shared()
	if !released and release and current_tick + 1 == release_frame:
		_release()
		released = true
	if !released:
		host.opponent.colliding_with_opponent = false
		host.colliding_with_opponent = false
	update_throw_position()

func _tick_after():
	._tick_after()
	if !released:
		host.update_data()
		var throw_pos = host.get_global_throw_pos()
		host.opponent.set_pos(throw_pos.x, throw_pos.y)

func _exit():
	released = false
#
#
#func get_real_hitstun():
#	var creator = host.get_fighter()
#	if creator:
#		var ticks = hitstun_ticks if creator.combo_count <= 0 else combo_hitstun_ticks
#		var started_above_0 = ticks > 0
#		if creator.combo_proration > 0:
#			ticks -= Hitbox.PRORATION_HITSTUN_ADJUSTMENT_AMOUNT * creator.combo_proration
#		if host.is_in_group("Fighter"):
#			if (creator.current_state().state_name in creator.combo_moves_used):
#				ticks = Utils.int_max(ticks - (Hitbox.COMBO_SAME_MOVE_HITSTUN_DECREASE_AMOUNT * (creator.combo_moves_used[creator.current_state().state_name] + 1)), ticks / 2)
#		if started_above_0 and ticks <= 0:
#			ticks = 1
#		return ticks
#	else:
#		return hitstun_ticks


func _release():
	throw = false
	if use_release_throw_pos:
		host.throw_pos_x = release_throw_pos_x
		host.throw_pos_y = release_throw_pos_y
	else:
		update_throw_position()
	var pos = host.get_global_throw_pos()
	host.opponent.set_pos(pos.x, pos.y)
	host.opponent.update_facing()
	var throw_data = HitboxData.new(self)
	host.opponent.hit_by(throw_data)
#	if increment_combo:
#		host.incr_combo()
	if screenshake_amount > 0 and screenshake_frames > 0 and !host.is_ghost:
		var camera = get_tree().get_nodes_in_group("Camera")[0]
		camera.bump(Vector2(), screenshake_amount, screenshake_frames / 60.0)
	if release_sfx and !ReplayManager.resimulating:
		release_sfx_player.play()
	if play_release_sfx_bass:
		host.play_sound("HitBass")
