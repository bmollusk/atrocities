extends Asset

var SPEED = 1500

var shoot_angle_offsets = {
	0: [PI/2, Vector2.ZERO],
	1: [5*PI/16+PI/2, Vector2(0, 44)],
	2: [6.5*PI/16+PI/2, Vector2(0, 48)],
	3: [7.5*PI/16+PI/2, Vector2(0, 60)],
	4: [8*PI/16+PI/2, Vector2(0, 70)],
	5: [8.5*PI/16+PI/2, Vector2(0, 64)],
	6: [9.5*PI/16+PI/2, Vector2(0, 64)],
	7: [10.5*PI/16+PI/2, Vector2(0, 64)],
	8: [PI+PI/2, Vector2(5, 64)],
	9: [3*PI/8+3*PI/2, Vector2(5, 64)],
	10: [3.5*PI/8+3*PI/2, Vector2(5, 60)],
	11: [3.8*PI/8+3*PI/2, Vector2(5, 62)],
	12: [4*PI/8+3*PI/2, Vector2(5, 66)],
	13: [4.5*PI/8+3*PI/2, Vector2(0, 50)],
	14: [4.8*PI/8+3*PI/2, Vector2(0, 52)],
	15: [5.5*PI/8+3*PI/2, Vector2(0, 54)],
	}

func _ready():
	super()
	var y = Globals.rotation_to_frame_coords(spawn_rotate,12)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y

func on_spawned():
	super()
	$Sprite2D/AnimationPlayer.play("shoot")
	var y = Globals.rotation_to_frame_coords(spawn_rotate, 12)
	$Bullet/Sprite2D.frame_coords.x = y

func _physics_process(delta):
	for bullet in $BulletSpawn.get_children():
		var y = Globals.rotation_to_frame_coords(spawn_rotate, 12)
		var index = Globals.rotation_to_frame_coords(spawn_rotate, 0)
		if index in shoot_angle_offsets:
			bullet.dir =  Vector2.from_angle(shoot_angle_offsets[index][0])
		else:
			bullet.dir = Vector2.DOWN.rotated(spawn_rotate)
		var collision = bullet.move_and_collide(bullet.dir*delta*SPEED)


func _on_sprite_2d_frame_changed():
	var y = Globals.rotation_to_frame_coords(spawn_rotate,12)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y

func shoot():
	var bullet: Projectile = $Bullet.duplicate()
	var index = Globals.rotation_to_frame_coords(spawn_rotate, 0)
	var offset
	var direction
	if index in shoot_angle_offsets:
		direction =  Vector2.from_angle(shoot_angle_offsets[index][0])
		offset = shoot_angle_offsets[index][1] + direction*100
	else:
		direction = Vector2.DOWN.rotated(spawn_rotate)
		offset = Vector2() + direction*100
	bullet.position+=offset
	bullet.damage = bullet.damage*spawn_scale
	bullet.init(card_type, card_name)
	$BulletSpawn.add_child(bullet)


func _on_animation_player_animation_finished(anim_name):
	await get_tree().create_timer((spawn_scale-1)*2).timeout
	$Sprite2D/AnimationPlayer.play("shoot")
