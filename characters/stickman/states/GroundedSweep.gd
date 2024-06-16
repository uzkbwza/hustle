extends "res://characters/states/Idle.gd"

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj.is_in_group("Fighter"):
		host.move_directly_relative(16, 0)
