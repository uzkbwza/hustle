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
