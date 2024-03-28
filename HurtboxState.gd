tool

extends CollisionBox

class_name HurtboxState

export var start_tick = 1
export var active_ticks = 1
export var endless = false

var started = false
var ended = false
var current_tick = 0

var prev_state

func _ready():
	z_index = 999

func start(host):
	started = true
	ended = false
	prev_state = {
		"width": host.hurtbox.width,
		"height": host.hurtbox.height,
		"x": host.hurtbox.x,
		"y": host.hurtbox.y,
		"can_draw": host.hurtbox.can_draw,	
	}
	host.hurtbox.width = width
	host.hurtbox.height = height

	host.hurtbox.x = x
	host.hurtbox.y = y
	
	host.hurtbox.can_draw = can_draw
	current_tick = 0

func tick(host):
	current_tick += 1
	if current_tick > active_ticks and !endless:
		ended = true
		end(host)

func copy_to(hurtbox_state):
	hurtbox_state.current_tick = current_tick
	if prev_state:
		hurtbox_state.prev_state = prev_state.duplicate(true)

func end(host):
	if not started:
		return
	started = false
	ended = false
	if prev_state != null:
		host.hurtbox.width = prev_state.width
		host.hurtbox.height = prev_state.height
		host.hurtbox.x = prev_state.x
		host.hurtbox.y = prev_state.y
		host.hurtbox.can_draw = prev_state.can_draw
		prev_state = null

func can_draw_box():
	if editor_selected:
		return true
