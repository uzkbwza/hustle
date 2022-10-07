extends Control

const BAR_PADDING = 1
const READY_COLOR = Color("1d8df5")
const NORMAL_COLOR = Color("04579a")
export var reverse = false

onready var ready_label = $ReadyLabel

var fighter: Fighter

func _process(delta):
	if is_instance_valid(fighter):
		if fighter.bursts_available > 0:
			if !ready_label.visible:
				ready_label.show()
		else:
			if ready_label.visible:
				ready_label.hide()
		update()

func _draw():
	var rect_length = rect_size.x
	var bar_length = rect_length / float(fighter.MAX_BURSTS)
	var height = rect_size.y
	var meter_ratio = fighter.burst_meter / float(fighter.MAX_BURST_METER)
	if !reverse:
		for i in range(fighter.bursts_available):
			var x = bar_length * i
			draw_rect(Rect2(x, 0, bar_length - BAR_PADDING, height), READY_COLOR, true)
		draw_rect(Rect2(fighter.bursts_available * bar_length, 0, (bar_length - BAR_PADDING) * meter_ratio, height), NORMAL_COLOR, true)
	else:
		for i in range(fighter.bursts_available):
			var x = rect_length - (bar_length * (1 + i))
			draw_rect(Rect2(x + BAR_PADDING, 0, bar_length - BAR_PADDING, height), READY_COLOR, true)
		var end = rect_length - ((fighter.bursts_available) * bar_length)
		var x = end - (bar_length - BAR_PADDING) * meter_ratio
		draw_rect(Rect2(x, 0, (bar_length - BAR_PADDING) * meter_ratio, height), NORMAL_COLOR, true)
