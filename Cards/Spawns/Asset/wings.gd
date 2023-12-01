extends Asset

var regen_tween:Tween
var SPEED = 100

func _ready():
	super()
	var y = Globals.rotation_to_frame_coords(spawn_rotate,0)
	$Sprite2D.frame_coords.y=y

func on_spawned():
	super()
	$Sprite2D/AnimationPlayer.play("spray")

func _on_sprite_2d_frame_changed():
	var y = Globals.rotation_to_frame_coords(spawn_rotate,0)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y

func _physics_process(delta):
	for instance in $FeatherSpawn.get_children():
		instance.move_and_collide(instance.dir*instance.speed*delta)

func spray():
	$AudioStreamPlayer2D.play()
	for i in range(randi_range(40*spawn_scale,50*spawn_scale)):
		var feather_instance: Projectile = $Feather.duplicate()
		var rand_pos = $FeatherSpawnPoints.get_children().pick_random().position
		feather_instance.position = rand_pos
		feather_instance.dir = Vector2.from_angle(spawn_rotate+PI/2+randf_range(-PI/4,PI/4))
		feather_instance.speed = SPEED*randf_range(1.5,2)*spawn_scale**1.2
		feather_instance.init(card_type, card_name)
		$FeatherSpawn.add_child(feather_instance)
	set_collision_mask_value(4, false)

func _on_animation_player_animation_finished(anim_name):
	if regen_tween and regen_tween.is_valid():
		regen_tween.kill()
	var regen_tween = create_tween()
	regen_tween.tween_property($Sprite2D, "modulate", Color.WHITE, 10*spawn_scale**1.5)
	regen_tween.tween_callback(func(): $Sprite2D/AnimationPlayer.play("spray"))
	
