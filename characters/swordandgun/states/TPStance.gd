extends CharacterState


func _enter():
	host.stance_teleport_x = data["x"]
	host.stance_teleport_y = data["y"]
