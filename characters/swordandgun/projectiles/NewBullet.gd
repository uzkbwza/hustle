extends BaseProjectile

class_name NewBullet

signal bullet_made_contact()

const SPEED = "50"
const NEW_BULLET = true

export var color = Color("f2ff31")

var dir_x = "0"
var dir_y = "0"
var arc_x = "0"
var arc_y = "0"

var last_pos_visual = Vector2()
var last_pos_visual_ricochet = Vector2()

var ricochet = false
var speed = SPEED
var no_draw_ticks = 0

var last_hit_by = ""

func init(pos=null):
	.init(pos)
	last_pos_visual = get_pos_visual()

func tick():
	last_pos_visual = get_pos_visual()
	.tick()
	pass

func reset_line():
	last_pos_visual = global_position
	pass

func reset_speed():
	speed = SPEED

func _draw():
	if !disabled:
		if no_draw_ticks > 0:
			return
		draw_line(to_local(last_pos_visual), Vector2(), color, 4.0)
		if to_local(last_pos_visual) == Vector2():
			draw_circle(Vector2(), 6.0, color)

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj == get_opponent():
		emit_signal("bullet_made_contact")

func on_got_blocked():
	emit_signal("bullet_made_contact")

func on_got_push_blocked():
	hitlag_ticks += 10

func hit_by(hitbox):
	if hitbox.hitbox_type == Hitbox.HitboxType.Flip:
		dir_x = fixed.mul(dir_x, "-1")
		return
	var dir = fixed.normalized_vec(hitbox.dir_x, hitbox.dir_y)
	dir_x = fixed.mul(dir.x, get_hitbox_x_dir(hitbox))
	dir_y = dir.y
	var hitter = obj_from_name(hitbox.host)
	
	if hitter:
		if hitter.is_in_group("Fighter"):
			last_hit_by = hitbox.host
		current_state().on_bounce(true,"0.8")
		speed = fixed.add(speed, hitbox.knockback)

		if hitter.get("NEW_BULLET"):
			var random_angle = randi_range(0, 361)
			var random_dir = fixed.angle_to_vec(fixed.div(fixed.mul(str(random_angle), "6.28318530"), "360"))
			dir_x = random_dir.x
			dir_y = random_dir.y
			get_fighter().parry_effect((get_center_position_float() + hitter.get_center_position_float()) / 2, true)
			disable()
			hitter.disable()
	.hit_by(hitbox)

func get_owned_fighter():
	if last_hit_by == "":
		return get_fighter()
	var obj = obj_from_name(last_hit_by)
	if obj:
		return obj.get_fighter()
