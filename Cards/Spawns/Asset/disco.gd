extends Asset


var SPEED = 500
var damage = 15
var dir: Vector2

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	super(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id)
	apply_scale(spawn_scale*Vector2.ONE)

func on_spawned():
	super()
	$Sprite2D/AnimationPlayer.play("disc", -1, 1/spawn_scale)
	dir = Vector2.DOWN.rotated(spawn_rotate)
	SPEED/=spawn_scale
	damage*=spawn_scale
	set_collision_layer_value(4, true)

func _physics_process(delta):
	if fullyspawned:
		var collision = move_and_collide(dir*delta*SPEED)
		if collision:
			dir = dir.bounce(collision.get_normal())
			$AudioStreamPlayer2D.play()

func hitbox_entered(player):
	destroy()
