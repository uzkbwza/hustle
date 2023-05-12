extends RandomNumberGenerator

class_name BetterRng

const cardinal_dirs = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
const diagonal_dirs = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1)]
const ascii = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
const numbers = '0123456789'

static func ang2vec(angle):
	return Vector2(cos(angle), sin(angle))
	
func random_dir(diagonals=false, zero=false) -> Vector2:
	var dirs = []
	dirs.append_array(cardinal_dirs)
	if diagonals:
		dirs.append_array(diagonal_dirs)
	if zero:
		dirs.append_array([Vector2(0, 0)])
	return choose(dirs)


func spread_vec(vec: Vector2, spread_degrees: float) -> Vector2:
	return vec.rotated(spread_angle(spread_degrees))

func spread_angle(degrees):
	return randf_range(deg2rad(-degrees/2.0), deg2rad(degrees/2.0))

func random_angle() -> float:
	return randf_range(0, TAU)
	
func random_angle_centered() -> float:
	return randf_range(0, TAU) - TAU/2

func random_vec(normalized=true) -> Vector2:
	return ang2vec(random_angle()) * (randf_range(0, 1) if !normalized else 1)

func random_sign() -> int:
	return 1 if coin_flip() else -1

func choose(array):
	var i = self.randi()
	return array[i % len(array) - 1]

func percent(percent: float) -> bool:
	return randf_range(0, 100) < percent

func coin_flip() -> bool:
	return self.randi() % 2 == 0

func random_point_in_rect(rect: Rect2) -> Vector2:
	return Vector2(randf_range(rect.position.x, rect.end.x), randf_range(rect.position.y, rect.end.y))

func weighted_randi_range(start: int, end: int, weight_function: FuncRef) -> int:
	var weight_sum = 0
	var weights = []
	for i in range(start, end):
		var weight: int = weight_function.call_func(i)
		weights.append(weight)
		weight_sum += weight
	var rnd = randi_range(0, weight_sum)
	for i in range(start, end):
		var weight = weights[start + i]
		if rnd <= weight:
			return i
		rnd -= weight
	assert(false, "should never get here")
	return 0

func weighted_choice(array: Array, weight_array: Array = []):
	# by default will weight items to favor those closer to the beginning
	if weight_array == []:
		for i in range(len(array)):
			weight_array.append(len(array) - i)
	var start = 0
	var end = len(array)
	var weight_sum: int = 0
	var weights = []
	for i in range(start, end):
		var weight: int = weight_array[i]
		weights.append(weight)
		weight_sum += weight
	var rnd = randi_range(0, weight_sum)
	for i in range(start, end):
		var weight = weights[start + i]
		if rnd <= weight:
			return i
		rnd -= weight
	assert(false, "should never get here")
	return 0

func func_weighted_choice(array: Array, weight_function: FuncRef):
	return array[weighted_randi_range(0, array.size(), weight_function)]

func random_string(length: int):
	var string = ''
	for i in range(length):
		string = string + choose(ascii)
	return string

func random_number_string(length: int):
	var string = ''
	for i in range(length):
		string = string + choose(numbers)
	return string
