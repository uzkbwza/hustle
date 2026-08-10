extends BaseObj

signal got_parried()

class_name BaseProjectile

export var immunity_susceptible = true
export var roll_immunity_susceptible = true
export var deletes_other_projectiles = true
export var fizzle_on_ceiling = false
export var movable = true
export var can_be_hit_by_melee = false
export var hit_by_self_projectiles = false
export var hit_cancel_on_hit = false
export var free_cancel_on_hit = false
export var apply_hitlag_when_hit_by_melee = true
#export var can_be_hit_by_projectiles = false
export var projectile_immune = false
export var hitlag_modifier = "1.0"
# Set false on a projectile to keep Ninja's grappling hook from latching
# onto it (the hook iterates objs_map looking for things in its lock zone
# and would otherwise pin to any projectile in range — e.g. Mutant's
# GasBomb, which is supposed to keep drifting).
export var hookable = true

var got_parried = false

var stopped = false

func _ready():
	state_variables.append_array(
		["got_parried", "immunity_susceptible", "roll_immunity_susceptible", "hit_by_self_projectiles", "deletes_other_projectiles", "fizzle_on_ceiling", "movable", "can_be_hit_by_melee", "hit_cancel_on_hit", "projectile_immune", "hitlag_modifier", "stopped"]
	)

func get_opponent():
	if is_instance_valid(creator):
		return creator.get_opponent()
	else:
		if id == 1:
			return get_p2()
		else:
			return get_p1()

func get_fighter():
	if is_instance_valid(creator):
		return creator.get_fighter()
	else:
		if id == 1:
			return get_p1()
		else:
			return get_p2()

func disable():
	sprite.hide()
	state_machine.hide()
	collision_box.hide()

	hurtbox.hide()
	disabled = true
	for hitbox in get_active_hitboxes():
		hitbox.deactivate()
	stop_particles()
	# _process stops calling update() once disabled, so any custom _draw
	# output (e.g. NewBullet's trail line) would stay on screen forever.
	# Trigger one final redraw — the _draw funcs early-out on `disabled`,
	# clearing whatever was previously drawn.
	update()
	if hooks:
		hooks.on_disable()


func on_got_parried():
	emit_signal("got_parried")
	if hooks:
		hooks.on_got_parried()

func is_playing_sounds():
	for sound_node in sounds.values():
		if sound_node and sound_node.playing:
			return true
	
	if $Sounds.get_child_count() > 0:
		for sound_nodes in $Sounds.get_children():
			if sound_nodes and sound_nodes.playing:
				return true
	# The 2 checks above check for sounds playing via the Sound node/Array
	
	for state in state_machine.get_children():
		for sound_state in state.get_children():
			if sound_state is VariableSound2D:
				if sound_state.playing:
					return true
	# This check for sounds playing through the state
			if sound_state is Hitbox:
				var hitbox_players = [
					sound_state.hit_sound_player,
					sound_state.whiff_sound_player,
					sound_state.hit_bass_sound_player,
				]
				for player in hitbox_players:
					if player and player.playing:
						return true
	# This checks for sounds playing through the hitbox of states
		var state_players = [
			state.enter_sfx_player,
			state.sfx_player,
		]
		for player in state_players:
			if player and player.playing:
				return true
	# This also check for sounds playing through the state as a just in case
	# moment if the previous state check doesn't work
	return false
	

func _process(delta):
	if !disabled:
		update()
	else:# only runs once the projectile is disabled
		if not is_playing_sounds():
			# checks if any instance of sound is playing, if not,
			# it then calls the func to delete. without the check, sounds would not play
			# as they would be deleted before finish playing
			call_deferred("free_object")

func free_object():
	if !is_ghost:
		# Safeguard because I don't know if prediction can handle it
		objs_map.erase(obj_name)
		# erases itself from objs_map
		# since it shares the var with everything else, all other instances will also
		# have this obj_name removed
		queue_free()
		# safely deletes the projectile at the end of the frame

func on_hit_ceiling():
	# super fires hooks.on_hit_ceiling() (BaseObj.on_hit_ceiling was empty
	# before the hook, so this override must call it through now).
	.on_hit_ceiling()
	if fizzle_on_ceiling:
		disable()

func can_hit_cancel(_fighter):
	return hit_cancel_on_hit

func hit_by(hitbox):
	if hooks:
		hooks.hit_by(hitbox)
	if hitbox:
		if hitbox.throw:
			return
		hitlag_ticks = fixed.round(fixed.mul(hitlag_modifier, str(hitbox.victim_hitlag)))
		if objs_map.has(hitbox.host):
			var host = objs_map[hitbox.host]
			var host_hitlag_ticks = fixed.round(fixed.mul(hitlag_modifier, str(hitbox.hitlag_ticks)))
			if apply_hitlag_when_hit_by_melee:
				if host.hitlag_ticks < host_hitlag_ticks:
					host.hitlag_ticks = host_hitlag_ticks
			if free_cancel_on_hit and host.is_in_group("Fighter"):
				host.projectile_free_cancel()
		if hitbox.rumble:
			rumble(hitbox.screenshake_amount, hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames)
	.hit_by(hitbox)
