extends Node

var items = {
	
}

var times = {
	
}

var enabled = false
var unlock_everything = true
var text_enabled = false
var ai_enabled = false
var disable_parts = false
var regen_meter = false
var dbg_function

func dbg_enabled(id, value):
	items[id] = value

func dbg_disabled(_id, _value):
	pass

func _process(delta):
	if Input.is_action_just_pressed("debug_activate_ai"):
		ai_enabled = !ai_enabled

#class TimeLength:
#	var length
#	var name

#	func _init(name, length):
#		self.name = name
#		self.length = length / 1000.0
#		pass
#
#func time_function(object: Object, method: String, args: Array):
#	var start = OS.get_ticks_usec()
#	object.callv(method, args)
#	var end = OS.get_ticks_usec()
#	if times.has(method):
#		times[method].append(TimeLength.new(method, end - start))
#	else:
#		times[method] = [TimeLength.new(method, end - start)]

func _enter_tree():
	if enabled and text_enabled:
		dbg_function = funcref(self, "dbg_enabled")
	else:
		dbg_function = funcref(self, "dbg_disabled")

#func _process(delta):
#	yield(get_tree(), "idle_frame")
#	for time_array in times:
#		var total_time = 0
#		for time in times[time_array]:
#			total_time += time.length
#		var avg_time = total_time / float(len(times[time_array]))
#		dbg(time_array, total_time)
#		dbg(time_array + "avg", avg_time)
##		dbg_max(time_array + " max", total_time)
#		times[time_array] = []

func dbg(id, value):
	dbg_function.call_func(id, value)

func dbg_count(id, value, min_=1):
	if value >= min_:
		dbg(id, value)

func dbg_remove(id):
	items.erase(id)

func dbg_max(id, value):
	if !items.has(id) or items[id] < value:
		dbg(id, value)

func lines() -> Array:
	var lines = []
	for id in items:
		lines.append(str(id) + ": " + str(items[id]))
	return lines
