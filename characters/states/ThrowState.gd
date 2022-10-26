extends CharacterState

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
export var reverse = false
export var disable_collision = true
export var ground_bounce = true

var hit_height = Hitbox.HitHeight.Mid
var hitlag_ticks = 0
var victim_hitlag = 0
var throw = true

func _enter_shared():
	throw = true
	host.colliding_with_opponent = false
	host.opponent.colliding_with_opponent = false
	host.throw_pos_x = start_throw_pos_x
	host.throw_pos_y = start_throw_pos_y
	if reverse:
		host.set_facing(-host.get_facing_int())
	released = false
	host.start_invulnerability()
	._enter_shared()

func _tick_shared():
	._tick_shared()
	if release and current_tick + 1 == release_frame:
		_release()
		released = true
	if !released:
		var throw_pos = host.get_global_throw_pos()
		host.opponent.set_pos(throw_pos.x, throw_pos.y)

func _release():
	throw = false
	host.throw_pos_x = release_throw_pos_x
	host.throw_pos_y = release_throw_pos_y
	var pos = host.get_global_throw_pos()
	host.opponent.set_pos(pos.x, pos.y)
	host.opponent.update_facing()
	var throw_data = HitboxData.new(self)
	host.opponent.hit_by(throw_data)
