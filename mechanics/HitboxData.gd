class_name HitboxData

var hit_height: int
var hitstun_ticks: int
var facing: String
var knockback: String
var dir_y: String
var dir_x: String
var knockdown: bool
var hitlag_ticks
var aerial_hit_state
var grounded_hit_state
var damage
var name
var throw

func _init(state):
	hit_height = state.hit_height
	hitstun_ticks = state.hitstun_ticks
	facing = state.host.get_facing()
	knockback = state.knockback
	dir_y = state.dir_y
	hitlag_ticks = state.hitlag_ticks
	dir_x = state.dir_x
	knockdown = state.knockdown
	aerial_hit_state = state.aerial_hit_state
	grounded_hit_state = state.grounded_hit_state
	damage = state.damage
	name = state.name
	throw = state.throw
