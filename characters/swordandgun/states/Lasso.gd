extends CharacterState

const LASSO_SCENE = preload("res://characters/swordandgun/projectiles/Lasso.tscn")
#const LASSO_LIFT = 6
const THROW_SPEED = "14"

var lasso_hit = false
var lasso_hit_frame = 0

onready var ANIM_LENGTH = anim_length

func _enter():
	anim_length = ANIM_LENGTH
	lasso_hit = false
#	endless = false
	lasso_hit_frame = 0
	fallback_state = "Wait"

func _frame_7():
	var obj = host.spawn_object(LASSO_SCENE, 16, -16)
	host.lasso_projectile = obj.obj_name
	var dir = xy_to_dir(data.x, data.y)
	var force = fixed.vec_mul(fixed.mul(dir.x, str(host.get_facing_int())), dir.y, THROW_SPEED)
	obj.apply_force_relative(force.x, force.y)
	var vel = host.get_vel()
	obj.apply_force(vel.x, vel.y)
	obj.connect("lasso_hit", self, "on_lasso_hit")

func on_lasso_hit(_opponent):
#	if !active:
#		return
	lasso_hit = true
	lasso_hit_frame = current_tick
	var opp_pos = host.opponent.get_hurtbox_center()
	var obj = host.obj_from_name(host.lasso_projectile)
	if obj:
		obj.set_pos(opp_pos.x, opp_pos.y)
		host.change_state("LassoHit")
#	endless = true

func _tick():
	if host.lasso_projectile:
		var obj = host.objs_map[host.lasso_projectile]
		if !obj.is_connected("lasso_hit", self, "on_lasso_hit"):
			obj.connect("lasso_hit", self, "on_lasso_hit")
	
	host.apply_grav()
	host.apply_fric()
	host.apply_forces()

func _exit():
	if host.lasso_projectile and !lasso_hit:
		if host.objs_map[host.lasso_projectile]:
			host.objs_map[host.lasso_projectile].disable()
		host.lasso_projectile = null
		
func is_usable():
	var gun = host.obj_from_name(host.gun_projectile)
	if gun:
		if gun.lassoed:
			return false
	return .is_usable()
