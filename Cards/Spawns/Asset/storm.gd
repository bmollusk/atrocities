extends Asset

var SPEED = 50
var targets = []
var dir

func _ready():
	super()
	dir = Vector2.DOWN.rotated(spawn_rotate)
	$Sprite2D/AnimationPlayer.play("storm")
	$HomingRadius.scale = (1/spawn_scale)*Vector2.ONE
	$Lightning.damage = spawn_scale*$Lightning.damage


func _physics_process(delta):
	if len(targets)>0:
		var target = targets[-1]
		dir = global_position.direction_to(target.global_position+Vector2.UP*randf_range(10, 20))
	if fullyspawned:
		var collision = move_and_collide(dir*delta*SPEED)
		if collision:
			dir = dir.bounce(collision.get_normal())


func _on_homing_radius_area_entered(area):
	targets.append(area)
	
func _on_homing_radius_area_exited(area):
	targets.erase(area)

func strike():
	var lightning: Projectile = $Lightning.duplicate()
	lightning.position = $LightningSpawn.position
	lightning.init(card_type, card_name)
	$LightningSpawn.add_child(lightning)
	$AudioStreamPlayer2D.play()


func _on_animation_player_animation_finished(anim_name):
	if anim_name=="backwards":
		if fullyspawned:
			strike()
		$Sprite2D/AnimationPlayer.play("storm")
	else:
		$Sprite2D/AnimationPlayer.play("backwards")


func _on_sprite_2d_frame_changed():
	var y = Globals.rotation_to_frame_coords(spawn_rotate, 0)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y
