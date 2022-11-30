extends PanelContainer

const SCROLL_SPEED = 110.0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _process(delta):
	if visible:
		$"%TickerText".rect_position.x -= SCROLL_SPEED * delta
		if $"%TickerText".rect_position.x < -$"%TickerText".rect_size.x:
			$"%TickerText".rect_position.x = $"%Ticker".rect_size.x
#		if start_size:
#			if Time.get_ticks_msec() % 500 == 0 or  randi() % 20 == 1:
#				var diff = (randi() % 3 - 1) * 0.5
#				$"%TextureRect".rect_size = Vector2(start_size.x + diff, start_size.y)
#			if Time.get_ticks_msec() % 100 == 0  or randi() % 200 == 1:
#				$"%TextureRect".rect_position = Vector2(-diff, 0)
