extends ObjectState
onready var hitbox = $Hitbox

func _on_hit_something(obj, hitbox):
	queue_state_change("Pop")
	
func _tick():
	if host.get_pos().y > -5:
		host.set_pos(host.get_pos().x, -5)
		var vel = host.get_vel()
		host.set_vel(vel.x, fixed.mul(fixed.abs(vel.y), "-0.25"))
