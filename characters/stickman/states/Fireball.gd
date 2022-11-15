extends CharacterState

const MOMENTUM_REDUCTION_X = "0.75"
const MOMENTUM_REDUCTION_Y = "0.75"

export(PackedScene) var projectile
export var projectile_x = 16
export var projectile_y = -16
export var speed_modifier_amount = "5.0"
export var push_back_amount = "-2.0"

var speed_modifier

var projectile_spawned = false

func _frame_0():
	var vel = host.get_vel()
	var new_vel_x = fixed.mul(vel.x, MOMENTUM_REDUCTION_X)
	var new_vel_y = fixed.mul(vel.y, MOMENTUM_REDUCTION_Y)
	host.set_vel(new_vel_x, new_vel_y)
	if data:
		speed_modifier = fixed.round(fixed.mul(fixed.sub(fixed.div(str(data.x), "100"), "0.5"), speed_modifier_amount))
	projectile_spawned = false

func _frame_4():
#	host.update_facing()
	projectile_spawned = true
	var object = host.spawn_object(projectile, projectile_x, projectile_y, true, {"speed_modifier": speed_modifier})
	var obj_state = object.state_machine.get_state("Default")
	if air_type == AirType.Grounded:
		host.apply_force_relative(push_back_amount, "0")

func _tick():
	host.apply_fric()
	host.apply_forces()
	if air_type == AirType.Aerial and projectile_spawned:
		host.apply_grav()
		if host.is_grounded():
			return "Landing"
