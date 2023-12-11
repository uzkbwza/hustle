extends BeastState

const PULL_SPEED = "1.5"
const REGEN = 25

var pulling = false

func _enter():
	pulling = false

func _frame_0():
	host.set_vel(host.get_vel().x, "0")
	host.start_rebirth_fx()

func detect(obj):
	if obj == host.opponent:
		pulling = true

func _tick():
	if pulling:
		var dir = host.opponent.get_opponent_dir_vec()
		var force = fixed.vec_mul(dir.x, dir.y, PULL_SPEED)
		host.opponent.apply_force(force.x, force.y if !host.opponent.is_grounded() else "0")

func on_got_blocked():
	host.refresh_air_movements()
	host.add_juke_pips(host.JUKE_PIPS_PER_USE - 1)
	pulling = false
	host.hp += REGEN

func _frame_11():
	host.stop_rebirth_fx()

func _frame_14():
	pulling = false

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj.is_in_group("Fighter"):
		host.refresh_air_movements()
		host.add_juke_pips(host.JUKE_PIPS_PER_USE - 1)
		pulling = false
		host.hp += REGEN

func _exit():
	host.stop_rebirth_fx()
