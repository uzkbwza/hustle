extends WizardState

const PROJECTILE_X = 40
const PROJECTILE_Y = -16

func _frame_9():
	var obj = host.spawn_object(preload("res://characters/wizard/projectiles/FlameWave.tscn"), PROJECTILE_X, PROJECTILE_Y)
	host.can_flame_wave = false

func is_usable():
	return .is_usable() and host.can_flame_wave and host.flame_wave_cooldown <= 0
