extends BaseProjectile

var hp = 2

func disable():
	.disable()
	creator.shockwave_projectile = null

func on_got_blocked():
	disable()
	
func hit_by(hitbox):
	.hit_by(hitbox)
	var obj = obj_from_name(hitbox.host)
	if obj == get_opponent() and current_state().state_name == "Default" and !hitbox.throw:
		hp -= 1
		if hp <= 0:
			change_state("FizzleOut")
