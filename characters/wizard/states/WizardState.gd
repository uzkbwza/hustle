extends CharacterState

class_name WizardState

export var trigger_orb_attack = true
export var trigger_orb_type = ""
export var trigger_orb_delay = 20

func _tick_shared():
	if current_tick == 0:
		if trigger_orb_attack:
			if host.orb_projectile:
				host.objs_map[host.orb_projectile].trigger_attack(trigger_orb_type, trigger_orb_delay)
	return ._tick_shared()
