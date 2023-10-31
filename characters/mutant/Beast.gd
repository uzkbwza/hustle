extends Fighter

class_name Mutant

const INSTALL_TICKS = 120

var install_ticks = 0
var shockwave_projectile = null
var spike_projectile = null

func process_extra(extra):
	.process_extra(extra)
	if extra.has("spike_enabled"):
		var obj = obj_from_name(spike_projectile)
		if obj:
			if !extra.spike_enabled:
				obj.disable()
