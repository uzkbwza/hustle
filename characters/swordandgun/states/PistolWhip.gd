extends CharacterState

func can_feint():
	return .can_feint() and host.current_state().name != "Brandish" and host.current_state().name != "QuickerDraw"

func can_draw_cancel():
	return host.current_state().name != "Brandish" and host.current_state().name != "QuickerDraw"

func is_usable():
	return .is_usable() and host.has_gun
