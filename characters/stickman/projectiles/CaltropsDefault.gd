extends DefaultFireball

onready var hitbox = $Hitbox

func _tick():
	._tick()
	if host.is_grounded():
		host.has_projectile_parry_window = false
		hitbox.hit_height = Hitbox.HitHeight.Low
	else:
		host.has_projectile_parry_window = true
		hitbox.hit_height = Hitbox.HitHeight.Mid

func _got_parried():
	host.disable()

func _on_hit_something(obj, _hitbox):
	if obj.is_in_group("Fighter") and obj.id != host.id:
		host.disable()
