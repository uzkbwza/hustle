extends ThrowState

const TRIGGER_ORB_TYPE = "Sword"
const TRIGGER_ORB_DELAY = 50

func _enter():
	._enter()
	if host.orb_projectile:
		var obj = host.obj_from_name(host.orb_projectile)
		if obj:
			obj.trigger_attack(TRIGGER_ORB_TYPE, TRIGGER_ORB_DELAY)
