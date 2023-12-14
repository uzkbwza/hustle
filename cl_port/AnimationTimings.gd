extends "res://characters/states/CharState.gd"
# this is an extra script that makes use of a multiline string to determine which animation frames correspond to what attack frames, making balancing way easier
# if you wanna use this for your character, just copy everything from the line below onwards and paste it into your decompiled project's CharState.gd
############### EXTENSION ###############
export (String, MULTILINE) var animation_timings = ""
var anim_timing_frames = []

func get_animPercent(_frame, _start, _end) -> float:
	var __frame = float(str(_frame) + ".0")
	var __start = float(str(_start) + ".0")
	var __end = float(str(_end) + ".0")
	return((__frame - __start) / max((__end - __start), 1))

func update_timing_frames():
	if (animation_timings != ""):
		var animData = []
		var txtLines = Utils.split_lines(animation_timings)
		for i in len(txtLines):
			animData.append([0, 0, 1, anim_length - 1])
			var sep = txtLines[i].split(" ")
			var datFrames = sep[0].split("-")
			var datLoops = 1
			if len(datFrames) > 2:
				datLoops = max(int(datFrames[2]), 1)
			if sep[1] == "f":
				sep[1] = str(anim_length - 1)

			animData[i] = [int(datFrames[0]), int(datFrames[1]), datLoops, int(sep[1])]
		
		anim_timing_frames = []
		var curStart = 0
		var datInd = 0
		for i in anim_length:
			var prevEndAnim = animData[datInd][3]
			if (get_animPercent(i, curStart, prevEndAnim) > 1):
				curStart = prevEndAnim + 1
				datInd += 1
			
			var curDat = animData[datInd]
			var startAnim = curDat[0]
			var endAnim = curDat[1]
			var datLoops = curDat[2]
			var endFrame = curDat[3]

			var animPercent = get_animPercent(i, curStart, endFrame)
			var animLen = endAnim - startAnim + 1
			
			var finalFrame = startAnim + (int(clamp(animLen * animPercent * datLoops, 0, endAnim - startAnim)) % animLen)
			anim_timing_frames.append(finalFrame)


func update_sprite_frame():
	if ReplayManager.resimulating:
		return 
	if not host.sprite.frames.has_animation(anim_name):
		return
	if host.sprite.animation != anim_name:
		host.sprite.animation = anim_name
		host.sprite.frame = 0
	if (animation_timings == ""):
		var sprite_tick = current_tick / ticks_per_frame

		var frame = (sprite_tick % sprite_anim_length) if loop_animation else Utils.int_min(sprite_tick, sprite_anim_length)
		host.sprite.frame = frame
	else:
		update_timing_frames()
		host.sprite.frame = anim_timing_frames[min(current_tick, anim_length - 1)]