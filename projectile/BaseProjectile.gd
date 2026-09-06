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

# Sim-tick counter since this projectile was disabled. Driven by
# game.reclaim_disabled_husks() (disabled projectiles aren't ticked themselves),
# so it advances once per tick on every peer. Once it crosses the linger
# threshold the husk is detached from sim and freed — see game.gd. Plain var,
# not state: resim re-spawns and re-disables at the same ticks so it
# re-accumulates identically, and copy_to never copies disabled objects.
var disabled_linger = 0

func _ready():
	state_variables.append_array(
		["got_parried", "immunity_susceptible", "roll_immunity_susceptible", "hit_by_self_projectiles", "deletes_other_projectiles", "fizzle_on_ceiling", "movable", "can_be_hit_by_melee", "hit_cancel_on_hit", "projectile_immune", "hitlag_modifier", "stopped"]
	)

func get_opponent():
	# is_instance_valid, not truthiness: a projectile's creator can itself be a
	# projectile that got reclaimed (freed), leaving a non-null but invalid ref
	# that errors on access. Fall back to the id-based opponent in that case.
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

# True while any sound this projectile owns is still audible. game.gd checks
# this before freeing a detached husk so a tail sound (hit/fizzle/whiff) isn't
# cut off. Covers the four places a projectile can be playing audio from:
# the `sounds` dict, raw $Sounds children, per-state VariableSound2D, and the
# hitbox / state sfx players. (Adapted from Furious's projectile-deletion patch.)
func is_playing_sounds():
	for sound_node in sounds.values():
		if sound_node and sound_node.playing:
			return true

	for sound_node in $Sounds.get_children():
		if sound_node and sound_node.playing:
			return true

	for state in state_machine.get_children():
		for child in state.get_children():
			if child is VariableSound2D:
				if child.playing:
					return true
			if child is Hitbox:
				for player in [child.hit_sound_player, child.whiff_sound_player, child.hit_bass_sound_player]:
					if player and player.playing:
						return true
		for player in [state.enter_sfx_player, state.sfx_player]:
			if player and player.playing:
				return true
	return false

func _process(delta):
	if !disabled:
		update()

func on_hit_ceiling():
	# super fires hooks.on_hit_ceiling() (BaseObj.on_hit_ceiling was empty
	# before the hook, so this override must call it through now).
	.on_hit_ceiling()
	if fizzle_on_ceiling:
		disable()

func can_hit_cancel(_fighter):
	return hit_cancel_on_hit



func is_invulnerable_to(hitbox, attacker):
	if !hitbox.hits_projectiles:
		return true
	return .is_invulnerable_to(hitbox, attacker)



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
