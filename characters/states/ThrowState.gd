extends CharacterState

var released = false

export var _c_Throw_Data = 0
export var release_frame = 1

func _enter_shared():
	released = false
	._enter_shared()

func _tick_shared():
	if current_tick + 1 = release_frame:
		_release()

func _release():
	opponent.hit_by()
