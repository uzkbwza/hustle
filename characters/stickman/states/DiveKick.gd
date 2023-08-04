extends CharacterState

const MOMENTUM_REDUCTION = "0.75"

export var move_x = 3
export var move_y = 3

export var x_modifier_amount = 2
export var y_modifier_amount = 2

export var grounded = false

var move_x_modifier = 0
var move_y_modifier = 0

var moving = false


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
	moving = false
	move_x_modifier = abs(data.x) * x_modifier_amount
	move_y_modifier = data.y * y_modifier_amount

func _frame_4():
	if grounded:
		spawn_particle_relative(particle_scene, Vector2(), Vector2(0, -1))

func _frame_11():
	host.reset_momentum()
	host.apply_force_relative(move_x + move_x_modifier, move_y + move_y_modifier)

func _frame_12():
#	host.update_facing()
	moving = true
	

func _tick():
	if !grounded and current_tick == 3:
		
		if host.initiative:
			current_tick = 9
	if moving:
		host.move_directly_relative(move_x + move_x_modifier, move_y + move_y_modifier)
	else:
		host.apply_forces()
		
	if host.is_grounded() and current_tick > 5:
		host.reset_momentum()
		host.apply_force_relative((move_x + move_x_modifier) / 2, 0)
		return "Landing"
