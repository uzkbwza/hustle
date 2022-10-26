extends PlayerInfo

var tween: SceneTreeTween

func set_fighter(fighter):
	.set_fighter(fighter)
	fighter.connect("bullet_used", self, "_on_bullet_used")
	if player_id == 2:
		$HBoxContainer.alignment = BoxContainer.ALIGN_END
	set_frame(0)

func _on_bullet_used():
	var frame = (5 - fighter.bullets_left) * 4
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
#	tween.set_trans(Tween.TRANS_QUAD)
#	tween.set_ease(Tween.EASE_IN)
	tween.tween_method(self, "set_frame", float(frame + 1), float(frame + 4), 0.1)

func set_frame(frame: float):
	$"%Cylinder".texture.current_frame = floor(clamp(frame, 0, $"%Cylinder".texture.frames))
