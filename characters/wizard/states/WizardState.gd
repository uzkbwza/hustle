extends CharacterState

class_name WizardState

export var trigger_orb_attack = true
export var trigger_orb_type = ""
export var trigger_orb_delay = 20

func _frame_0():
	iasa_at = -1

func _tick_shared():

	if current_tick == 0:
		if trigger_orb_attack:
			if host.orb_projectile:
				host.objs_map[host.orb_projectile].trigger_attack(trigger_orb_type, trigger_orb_delay)
	._tick_shared()

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	iasa_at = 11
	pass
