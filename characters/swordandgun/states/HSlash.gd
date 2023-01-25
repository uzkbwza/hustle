extends CharacterState

func _enter():
	if data:
		if data.y != 0:
			return "HSlashUp"
