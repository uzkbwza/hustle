extends ObjectState

class_name DefaultFireball

export var _c_Projectile_Dir = 0
export var move_x = 4
export var move_y = 0
export var move_x_string = "0"
export var move_y_string = "0"
export var clash = true
export var num_hits = 1
export var lifetime = 999999
export var fizzle_on_ground = true
export var fizzle_on_walls = true
export var fizzle_on_hit_opponent = false

export var follow_creator = false

var hit_something = false
var hit_something_tick = 0

func _frame_0():
	hit_something = false
	hit_something_tick = 0
	host.set_grounded(false)

func _tick():
	var pos = host.get_pos()
	host.update_grounded()
	if !hit_something and ((host.is_grounded() and fizzle_on_ground) or (fizzle_on_walls and (pos.x <= -host.stage_width or pos.x >= host.stage_width))):
		fizzle()
		host.hurtbox.width = 0
		host.hurtbox.height = 0
		pass
	if current_tick >= lifetime:
		fizzle()
	elif !hit_something:
		move()
	if follow_creator:
		if host.creator:
			var creator_pos = host.creator.get_pos()
			host.set_pos(creator_pos.x, creator_pos.y)

func _on_hit_something(obj, _hitbox):
	if clash or (fizzle_on_hit_opponent and obj.is_in_group("Fighter")):
		if obj is BaseProjectile:
			if !obj.deletes_other_projectiles:
				return
		num_hits -= 1
		if num_hits == 0:
			fizzle()

func move():
	if data and data.has("speed_modifier"):
		host.move_directly_relative((move_x + data["speed_modifier"]) if move_x != 0 else 0, (move_y + data["speed_modifier"]) if move_y != 0 else 0)
	elif fixed.gt(move_x_string, "0") or fixed.gt(move_y_string, "0"):
		host.move_directly_relative(move_x_string, move_y_string)
		pass
	else:
		host.move_directly_relative(move_x, move_y)

func fizzle():
	hit_something = true
	host.disable()
	terminate_hitboxes()
	hit_something_tick = current_tick
