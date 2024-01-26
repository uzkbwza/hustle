extends HurtAerial

onready var self_hitbox = $Hitbox

var hit_self = false

func _frame_0():
	hit_self = false
	._frame_0()
	var obj = host.obj_from_name(hitbox.host)
	if obj and obj.get_fighter() == host:
		self_hitbox.activate()
		self_hitbox.add_hit_object(obj.obj_name)
		obj.damages_own_team == false
		hit_self = true
		obj.disable()

func _tick():
	if hit_self:
		host.opponent.reset_combo()
	return ._tick()

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	host.opponent.reset_combo()
