extends CharacterState

var hit = false

func _frame_0():
	host.z_index = -2

func _exit():
	host.z_index = 0

func _tick():
	host.apply_fric()
	host.apply_forces()

func _on_hit_something(obj, hitbox):
	hit = true
	._on_hit_something(obj, hitbox)
