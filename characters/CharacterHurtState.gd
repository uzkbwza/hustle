extends CharacterState

class_name CharacterHurtState
const HIT_GRAV = "0.25"
const HIT_FALL_SPEED = "15.0"

func init():
	.init()
	busy_interrupt_into.append("Nudge")

func _enter_shared():
	host.z_index = -1
#	host.colliding_with_opponent = false
	host.chara.set_gravity(HIT_GRAV)
	host.chara.set_max_fall_speed(HIT_FALL_SPEED)
	host.refresh_air_movements()
	host.state_interruptable = false
	host.busy_interrupt = true
	._enter_shared()
	
func _on_hit_something(_obj, _hitbox):
	pass

func _exit_shared():
	host.z_index = 0
	host.chara.set_gravity(host.gravity)
	host.chara.set_max_fall_speed(host.max_fall_speed)
	._exit_shared()

func can_interrupt():
	return false
