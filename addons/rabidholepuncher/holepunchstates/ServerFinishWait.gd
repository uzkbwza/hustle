""" ServerFinishWait """
extends HolePunchState

# Time to wait for server in seconds before starting communicating with other peers
const SERVER_FINISH_WAIT_SECONDS: float = 2.0

onready var _finish_timer: Timer = $FinishTimer
var previous_state_message: Dictionary

func _ready() -> void:
	yield(owner, "ready")
	_finish_timer.wait_time = SERVER_FINISH_WAIT_SECONDS
	_finish_timer.one_shot = true
	_finish_timer.connect("timeout", self, "_on_finish_timer_timeout")


func enter(msg: Dictionary = {}) -> void:
	debug("Enter " + self.name + " state")
	_finish_timer.start()
	previous_state_message = msg
	hole_puncher.emit_signal("holepunch_progress_update", 
								hole_puncher.STATUS_STARTING_SESSION, 
								hole_puncher._session_name,
								msg.keys())


func _on_finish_timer_timeout() -> void:
	_state_machine.transition_to("Greetings", previous_state_message)
