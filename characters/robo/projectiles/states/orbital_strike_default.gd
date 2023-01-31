extends DefaultFireball

#const MOVE_SPEED = "0.5"
const MOVE_T = "0.15"
const AIM_INCREASE = "0.004"
const FADE_IN_TIME = 6
const MAX_T = "0.50"

func _enter():
	host.sprite.modulate.a = 0

func _frame_0():
	host.set_pos(host.get_pos().x, 0)
#	host.play_sound("Beep")

func _tick():
	if current_tick < FADE_IN_TIME:
		host.sprite.modulate.a = current_tick / float(FADE_IN_TIME)
	else:
		host.sprite.modulate.a = 1.0
	if host.creator and host.creator.opponent:
		var dir = host.get_object_dir(host.creator.opponent)
		var pos = host.obj_local_center(host.creator.opponent)
#		if fixed.gt(fixed.vec_len(str(pos.x), str(pos.y)), "10.0"):
#			host.apply_force(fixed.mul(MOVE_SPEED, str(dir)), "0")
		var t = fixed.add(MOVE_T, fixed.mul(AIM_INCREASE, str(current_tick)))
		if fixed.gt(t, MAX_T):
			t = MAX_T
#		print(t)
		host.set_pos(fixed.round(fixed.lerp_string(str(host.get_pos().x), str(host.get_pos().x + pos.x), t)), 0)
	var drain_ratio = fixed.sub("1.0", fixed.div(str(current_tick), str(host.aim_ticks)))
	host.creator.loic_meter = fixed.round(fixed.mul(str(Robot.LOIC_METER), drain_ratio))
	if current_tick > host.aim_ticks:
		return "Fire"
#	var beep_mod = int(16 - ceil((current_tick / float(host.aim_ticks)) * 10))
#	if current_tick % beep_mod == 0:
	if !host.beep.playing:
		host.play_sound("Beep")