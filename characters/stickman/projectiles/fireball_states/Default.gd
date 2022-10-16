extends ObjectState

const FREE_AFTER_TICKS = 60

export var _c_Projectile_Dir = 0
export var move_x = 4
export var move_y = 0

var hit_something = false
var hit_something_tick = 0

func _enter():
	hit_something = false
	hit_something_tick = 0
	host.set_grounded(false)

func _tick():
	var pos = host.get_pos()
	host.update_grounded()
	if !hit_something and host.is_grounded() or pos.x < -host.stage_width or pos.x > host.stage_width:
		_on_hit_something(null, null)
		host.hurtbox.width = 0
		host.hurtbox.height = 0
		pass
	elif !hit_something:
		host.move_directly_relative((move_x + data["speed_modifier"]) if move_x != 0 else 0, (move_y + data["speed_modifier"]) if move_y != 0 else 0)
#	if hit_something:
#			host.queue_free()
#			if current_tick > hit_something_tick + FREE_AFTER_TICKS:

func _on_hit_something(_obj, _hitbox):
	terminate_hitboxes()
	host.sprite.hide()
	host.stop_particles()
	hit_something_tick = current_tick
	hit_something = true
	host.disabled = true
