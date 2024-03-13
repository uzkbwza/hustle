extends DefaultFireball

const UP_FORCE = "-0.3"
const FORWARD_FORCE = "0.01"
const FORWARD_INCREASE = "0.02"

var forward_force = FORWARD_FORCE

export var flying = false

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj and obj.is_in_group("Fighter"):
		host.disable()

func _tick():
	._tick()
	if flying:
		host.apply_force_relative(forward_force, UP_FORCE if fixed.gt(host.get_vel().y, "-0.8") else "0")
		forward_force = fixed.add(forward_force, FORWARD_INCREASE)
		if current_tick % 5 == 0:
			host.play_sound("FlySound")

func on_got_blocked():
	host.disable()
