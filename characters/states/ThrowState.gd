extends CharacterState

class_name ThrowState

var released = false

export var _c_Throw_Data = 0
export var release = false
export var release_frame = -1
export var start_throw_pos_x = 0
export var start_throw_pos_y = 0
export var release_throw_pos_x = 0
export var release_throw_pos_y = 0


export var _c_Release_Data = 0
export var hitstun_ticks: int = 0
export var knockback: String = "1.0"
export var dir_x: String = "1.0"
export var dir_y: String = "0.0"
export var knockdown: bool = true
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
export var wall_slam = false
#export var incr_combo = false

var hit_height = Hitbox.HitHeight.Mid
var hitlag_ticks = 0
var victim_hitlag = 0
var throw = true

#	released = false

func update_throw_position():
	var frame = host.get_current_sprite_frame()
	if frame in throw_positions:
		var pos = throw_positions[frame]
		host.throw_pos_x = pos.x
		host.throw_pos_y = pos.y

func _frame_0_shared():
	host.opponent.change_state("Grabbed")
	host.throw_pos_x = start_throw_pos_x
	host.throw_pos_y = start_throw_pos_y
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
		if reverse:
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

func _release():
	throw = false
	host.throw_pos_x = release_throw_pos_x
	host.throw_pos_y = release_throw_pos_y
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
