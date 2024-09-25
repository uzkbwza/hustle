extends CharacterState

const MOMENTUM_REDUCTION = "0.75"

export var move_x = 3
export var move_y = 3

export var x_modifier_amount = 2
export var y_modifier_amount = 2

export var grounded = false

var move_x_modifier = 0
var move_y_modifier = 0

var move_x_amount = "0"
var move_y_amount = "0"

var moving = false


onready var hitbox = $Hitbox

func _frame_0():
	if !(data is Dictionary):
		data = {
			x = 1,
			y = 1,
		}
	if !grounded:
		var vel = host.get_vel()
		var new_vel = fixed.mul(vel.x, MOMENTUM_REDUCTION)
		host.set_vel(new_vel, "0")
	else:
		anim_name = "DiveKick2"
		
		hitbox.y = -9
		hitbox.hits_vs_grounded = true
		hitbox.block_cancel_allowed = false
		hitbox.dir_y = "1.0"
		
		if data.y < 0:
			hitbox.hits_vs_grounded = false
			hitbox.block_cancel_allowed = true
			hitbox.dir_y = "-1.0"
			anim_name = "DiveKick2Up"
			hitbox.y -= 16
#			host.start_aerial_attack_invulnerability()
			
			
	moving = false
	move_x_modifier = abs(data.x) * x_modifier_amount
	move_y_modifier = data.y * y_modifier_amount

	move_x_amount = move_x + move_x_modifier
	move_y_amount = Utils.int_sign2(data.y) * move_y + move_y_modifier
	
	var move_amount = "1.0"
#	if data.y < 0:
#		move_amount = "0.6"

	move_x_amount = fixed.round(fixed.mul(str(move_x_amount), move_amount))
	move_y_amount = fixed.round(fixed.mul(str(move_y_amount), move_amount))
#	if host.combo_count > 0:
#		host.feinting = true
#
#func can_feint():
#	return .can_feint() and host.combo_count == 0

func _frame_4():
	if grounded:
		spawn_particle_relative(particle_scene, Vector2(), Vector2(0, -1))

func _frame_11():
	host.reset_momentum()
	host.apply_force_relative(move_x + move_x_modifier, move_y + move_y_modifier)

func _frame_12():
#	host.update_facing()
	moving = true
	
func _on_hit_something(obj, hitbox):
	if host.can_divekick_hop and !obj.is_in_group("Fighter") and obj.id == host.id:
		queue_state_change("DiveKickHop")
		host.feinting = false
		host.hitlag_ticks = 0
		host.can_divekick_hop = false
#		return
	._on_hit_something(obj, hitbox)
	if grounded:
#		host.reset_momentum()
		if data.y >= 0:
			host.set_vel(host.get_vel().x, "0")
		else:
			var move_y_amount = Utils.int_sign(data.y) * move_y + move_y_modifier
			move_y_amount = fixed.mul(str(move_y_amount), "0.6")
			host.set_vel(host.get_vel().x, move_y_amount)
		moving = false
		if obj.is_in_group("Fighter"):
			queue_state_change("Fall")


func on_got_perfect_parried():
	if data.y < 0:
		host.hitlag_ticks += 8
		


func _tick():
	if !grounded and current_tick == 3:
		if host.initiative:
			current_tick = 9
		else:
			current_tick = 6

	if grounded and data.y < 0 and current_tick == 4:
		current_tick = 8
	
	if data.y < 0 and current_tick > 20:
		return "DiveKickHopLong"

	if moving:
		host.move_directly_relative(move_x_amount, move_y_amount)
	else:
		host.apply_forces()

	if host.is_grounded() and current_tick > (5 if !grounded else 10):
		host.reset_momentum()
		host.apply_force_relative((move_x + move_x_modifier) / 2, 0)
		return "Landing"
