extends MarginContainer

var singleplayer = true

func get_data():
	return {
		"stage_width": int($"%StageWidth".value),
		"p2_dummy": $"%P2Dummy".pressed if singleplayer else false,
		"di_enabled": $"%DIEnabled".pressed,
		"turbo_mode": $"%TurboMode".pressed,
		"infinite_resources": $"%InfiniteResources".pressed,
		"one_hit_ko": $"%OneHitKO".pressed,
		"game_length": int($"%GameLength".value),
		"turn_time": int($"%TurnLength".value),
		"burst_enabled": $"%BurstEnabled".pressed,
		"frame_by_frame": $"%FrameByFrame".pressed,
		"always_perfect_parry": $"%AlwaysPerfectParry".pressed,
		"char_distance": int($"%CharDist".value),
	}

func init(singleplayer=true):
	$"%TurnLengthContainer".visible = !singleplayer
	if !singleplayer:
		if !Network.is_host():
			hide()
	$"%P2Dummy".visible = singleplayer
