extends DefaultFireball

onready var hitbox = $Hitbox

func _tick():
	._tick()
	if host.is_grounded():
		hitbox.hit_height = Hitbox.HitHeight.Low

func _got_parried():
	host.disable()
