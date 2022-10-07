extends CharacterState

const MOMENTUM_REDUCTION = "0.75"

export(PackedScene) var projectile
export var projectile_x = 16
export var projectile_y = -16
export var speed_modifier_amount = "5.0"
export var push_back_amount = "-2.0"

var speed_modifier

var projectile_spawned = false

func _enter():
	var vel = host.get_vel()
	var new_vel = fixed_math.mul(vel.x, MOMENTUM_REDUCTION)
	host.set_vel(new_vel, "0")
	if data:
		
		speed_modifier = fixed_math.round(fixed_math.mul(fixed_math.sub(fixed_math.div(str(data.x), "100"), "0.5"), speed_modifier_amount))
	projectile_spawned = false

func _frame_12():
	projectile_spawned = true
	var object = host.spawn_object(projectile, projectile_x, projectile_y)
	var obj_state = object.state_machine.get_state("Default")
	if obj_state.move_x != 0:
		obj_state.move_x += speed_modifier
	if obj_state.move_y != 0:
		obj_state.move_y += speed_modifier
	if air_type == AirType.Grounded:
		host.apply_force_relative(push_back_amount, "0")
		
	
func _tick():
	host.apply_fric()
	host.apply_forces()
	if air_type == AirType.Aerial and projectile_spawned:
		host.apply_grav()
		if host.is_grounded():
			return "Landing"
