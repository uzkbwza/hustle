extends Camera2D

class_name GoodCamera

const MAX_SHAKE_AMOUNT = 20
const SCREENSHAKE_MODIFIER = 1.0

export var default_screenshake_amount = 2.0
export var default_screenshake_time = 0.1
#@onready var noise = FastNoiseLite.new()
#var noise_y = 0

#var shake_tween
var shake_amount = 0
var rng = BetterRng.new()
#var _smoothing_speed

var offsets = []
var tweens = []

class Offset extends Reference:
	var rng: BetterRng
	var dir = Vector2()
	var amount: float = 0
	var random = false

	func get_value():
		if !random:
			return dir * amount
		else:
			return amount * rng.random_vec()
	
func _ready():
	rng.randomize()

func bump_at_location(dir, location=global_position, amount:=default_screenshake_amount, time:=default_screenshake_time, falloff=1400, power=4):
#	if !Global.screen_shake:
#		return
	bump(dir, amount - (1 - pow(1 - clamp((location.distance_to(global_position) / falloff), 0, 1), power)) * amount, time)

func reset_shake():
	offsets = []
	for tween in tweens:
		tween.reset()
	tweens = []
	
func bump(dir=Vector2(), amount=default_screenshake_amount, time=default_screenshake_time):
	if amount > MAX_SHAKE_AMOUNT:
		amount = MAX_SHAKE_AMOUNT
	amount *= SCREENSHAKE_MODIFIER
	amount = float(amount)
	time = float(time)
#	if !Global.screen_shake:
#		return
	var shake_tween = create_tween()
	shake_tween.set_parallel(false)
	shake_tween.set_trans(Tween.TRANS_EXPO)
	shake_tween.set_ease(Tween.EASE_OUT)
	var offs = Offset.new()
	offs.dir = dir
	offs.rng = rng
	
	if dir == Vector2():
		offs.random = true
	
	offsets.append(offs)
	
	shake_tween.tween_property(offs, "amount", amount, 0.0025)
	if !offs.random:
		shake_tween.set_trans(Tween.TRANS_ELASTIC)
	else:
		shake_tween.set_trans(Tween.TRANS_CIRC)
	shake_tween.set_ease(Tween.EASE_OUT)
	
#	shake_tween.set_parallel(true)
#	shake_tween.tween_property(self, "shake_amount", 0, time)
	shake_tween.tween_property(offs, "amount", 0.0, time)
#	tweens.append(shake_tween)
	yield(shake_tween, "finished")
	if !is_instance_valid(self):
		return
	shake_tween.kill()
#	offsets.erase(offs)
	offsets.erase(offs)


func _physics_process(delta):
#	smoothing_speed = _smoothing_speed / Engine.time_scale
	offset = Vector2()
#	if 1.0 / delta > 30:
	var offset_values = []
	for offs in offsets:
		var value = offs.get_value()
		offset += value
		offset_values.append(value)
#		Debug.dbg("offsets", len(offset_values))
#	else:
#		smoothing_enabled = false
#		offset = Vector2()
