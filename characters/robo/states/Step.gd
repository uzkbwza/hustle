extends RobotState

const MOVE_AMOUNT = 15
const EXTRA_FORWARD_MOVEMENT = 6
const FLIP_LAG = 2
const STARTUP_LAG = 3
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var charged = false

var startup_lag = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func _enter():
	if host.combo_count <= 0:
		startup_lag += STARTUP_LAG
	if host.reverse_state:
#		backdash_iasa = true
		beats_backdash = false
		startup_lag += FLIP_LAG
		host.add_penalty(10)
	else:
#		backdash_iasa = false
		beats_backdash = true

func _frame_0():
	if charged:
		host.has_projectile_armor = true

func _frame_5():
	if !host.reverse_state:
		host.move_directly_relative((EXTRA_FORWARD_MOVEMENT if !host.reverse_state else 0), 0) 

func _frame_6():
	self_interruptable = false
	next_state_on_hold = false
	next_state_on_hold_on_opponent_turn = false
	host.move_directly_relative(MOVE_AMOUNT , 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _frame_8():
	host.play_sound("Step")

func _frame_9():
	self_interruptable = true
	next_state_on_hold = true
	next_state_on_hold_on_opponent_turn = true
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, 10, 6 / 60.0)

func _tick():
	if current_tick >= 1 and startup_lag > 0:
		startup_lag -= 1
		current_tick = 1
	if charged:
		host.apply_forces_no_limit()
	else:
		host.apply_forces()
	pass
