extends BaseProjectile

const ACID_BUBBLE_SCENE = preload("res://characters/mutant/projectiles/AcidBubble.tscn")
const NUM_ACID_BUBBLES = 2
const ACID_BUBBLE_SPEED = "7"
const COOLDOWN = 35
const STARTUP = 5

onready var poison_particle = $Flip/Particles/PoisonParticle
onready var poison_particle_2 = $Flip/Particles/PoisonParticle2

var spawn_acid_bubble_cooldown = 0
var spawn_acid_bubble_startup = 0

func init(pos=null):
	.init(pos)
	get_fighter().opponent.connect("got_hit_by_fighter", self, "on_opponent_hit")
	get_fighter().opponent.connect("blocked_melee_attack", self, "on_opponent_hit")

func on_opponent_hit():
	if current_state().current_tick < 30 or spawn_acid_bubble_cooldown > 0:
		return

	spawn_acid_bubble_startup = STARTUP
	spawn_acid_bubble_cooldown = COOLDOWN

func tick():
	.tick()
	if get_fighter().opponent.combo_count > 0 and !("Burst") in get_opponent().current_state().state_name:
		disable()
		return
	if spawn_acid_bubble_cooldown > 0:
		spawn_acid_bubble_cooldown -= 1
		if spawn_acid_bubble_cooldown <= 0:
			spawn_acid_bubble_cooldown = 0
	if spawn_acid_bubble_startup > 0:
		spawn_acid_bubble_startup -= 1
		if spawn_acid_bubble_startup <= 0:
			spawn_acid_bubble_startup = 0
			for i in range((NUM_ACID_BUBBLES)):
				var projectile = spawn_object(ACID_BUBBLE_SCENE, 0, 0)
				var randangle = fixed_deg_to_rad(randi_static() % 360)
				var randdir = fixed.angle_to_vec(randangle)
				if i == 0:
					if fixed.lt(randdir.x, "0"):
						randdir.x = fixed.mul(randdir.x, "-1")
				if i == 1:
					if fixed.gt(randdir.x, "0"):
						randdir.x = fixed.mul(randdir.x, "-1")
				var force = fixed.vec_mul(randdir.x, randdir.y, ACID_BUBBLE_SPEED)
				projectile.apply_force(force.x, force.y)
				var opp_vel = get_fighter().opponent.get_vel()
				projectile.apply_force(opp_vel.x, opp_vel.y)
#	print(spawn_acid_bubble_cooldown)
