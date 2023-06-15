extends BaseProjectile

const SPEED = "50" 

var dir_x = "0"
var dir_y = "0"

var last_pos_visual = Vector2()
var last_pos_visual_ricochet = Vector2()

var ricochet = false
var speed = SPEED

var last_hit_by = ""

func init(pos=null):
	.init(pos)
	last_pos_visual = get_pos_visual()

func tick():
	last_pos_visual = get_pos_visual()
	.tick()
	pass

func _draw():
	if !disabled:
		draw_line(to_local(last_pos_visual), Vector2(), Color("f2ff31"), 4.0)
		if to_local(last_pos_visual) == Vector2():
			draw_circle(Vector2(), 6.0, Color("f2ff31"))

func hit_by(hitbox):
	if hitbox.hitbox_type == Hitbox.HitboxType.Flip:
		dir_x = fixed.mul(dir_x, "-1")
		return
	var dir = fixed.normalized_vec(hitbox.dir_x, hitbox.dir_y)
	dir_x = fixed.mul(dir.x, get_hitbox_x_dir(hitbox))
#	dir_x = dir.x
	dir_y = dir.y
	var hitter = obj_from_name(hitbox.host)
	if hitter.is_in_group("Fighter"):
		last_hit_by = hitbox.host
	current_state().on_bounce(true, false, false, "0.8")
	speed = fixed.add(speed, hitbox.knockback)


func get_owned_fighter():
	if last_hit_by == "":
		return get_fighter()
	var obj = obj_from_name(last_hit_by)
	if obj:
		return obj.get_fighter()
