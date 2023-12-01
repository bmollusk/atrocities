extends Asset

var float_dir: Vector2
var SPEED = 20


func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	super(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id)
	apply_scale(spawn_scale*Vector2.ONE)

func _ready():
	super()
	float_dir = Vector2.DOWN.rotated(spawn_rotate)
	$Sprite2D/AnimationPlayer.play("balloon")
	$Pop.visible = false
	
func on_spawned():
	super()
	$Timer.wait_time/=spawn_scale
	$Timer.start()
#make time associated with explosion impact
func _physics_process(delta):
	
	var collision: KinematicCollision2D = move_and_collide(float_dir*delta*SPEED+Vector2.UP*delta*5)
	if collision and collision.get_collider() != $Pop:
		float_dir = float_dir.bounce(collision.get_normal())
	for pop_part in $PopSpawn.get_children():
		var speed = randf_range(10, 20)
		pop_part.dir = pop_part.position
		pop_part.move_and_collide(pop_part.dir*delta*speed)
	
	if not $Sprite2D.visible and $PopSpawn.get_child_count()==0:
		destroy()


func _on_timer_timeout():
	$Sprite2D/AnimationPlayer.play("explosion")

func pop_balloon():
	$Sprite2D.visible = false
	set_collision_mask_value(4, false)
	SPEED/=2
	for i in range(30*spawn_scale):
		var pop_part: Projectile = $Pop.duplicate()
		var rand_pos = $PopSpawnPoints.get_children().pick_random().position
		var rand_rot = randf_range(0, 2*PI)
		pop_part.damage*= spawn_scale
		pop_part.position = rand_pos
		pop_part.rotation = rand_rot
		pop_part.init(card_type, card_name)
		$PopSpawn.add_child(pop_part)
	
func hitbox_entered(player):
	float_dir = player.global_position.direction_to(global_position)
