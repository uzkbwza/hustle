extends WizardState

func _enter():
	if data is Dictionary:
		if data.y != 0:
			return "IceSpikeAir2"
