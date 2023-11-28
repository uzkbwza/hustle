extends RobotState

onready var hitbox = $Hitbox
onready var hitbox_2 = $Hitbox2
onready var hitbox_3 = $Hitbox3
onready var hitbox_4 = $Hitbox4


func _frame_0():
	for h in [hitbox, hitbox_2, hitbox_3, hitbox_4]:
		if h.get("throw"):
			h.throw_state = "DisembowelGrabFollowup" if !data else "TryCatchGroundSlam"
		else:
			h.followup_state = "DisembowelGrabFollowup" if !data else "TryCatchGroundSlam"
