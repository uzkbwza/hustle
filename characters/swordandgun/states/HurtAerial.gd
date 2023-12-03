extends HurtAerial

onready var self_hitbox = $Hitbox

func _frame_0():
	var obj = host.obj_from_name(hitbox.host)
	if obj and obj.get_fighter() == host:
		self_hitbox.activate()
		self_hitbox.add_hit_object(obj.obj_name)
		obj.damages_own_team == false
		obj.disable()
