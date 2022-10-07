""" None """
extends HolePunchState


func enter(msg: Dictionary = {}) -> void:
	hole_puncher._server.close()
	hole_puncher._peer.close()
	debug("Enter " + self.name + " state")
	if msg.has(ERROR_STR):
		error("HolePunch failed, reason: " + str(msg[ERROR_STR]))
		hole_puncher.emit_signal("holepunch_failure", msg[ERROR_STR])
