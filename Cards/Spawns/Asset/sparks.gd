extends Asset

var SPEED = 50

func _ready():
	super()
	var y = Globals.rotation_to_frame_coords(spawn_rotate,0)
	$Sprite2D.frame_coords.y=y

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	super(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id)
	apply_scale(spawn_scale*Vector2.ONE)


func on_spawned():
	super()
	$Sprite2D/AnimationPlayer.play("sparkup")

func _on_sprite_2d_frame_changed():
	var y = Globals.rotation_to_frame_coords(spawn_rotate,0)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y

func _physics_process(delta):
	for instance in $SparkPoint.get_children():
		instance.move_and_collide(instance.dir*instance.speed*delta)

func spark():
	for i in range(randi_range(3*spawn_scale,10*spawn_scale)):
		var spark_instance: Projectile = $SparkTemplate.duplicate()
		spark_instance.scale = randf_range(0.5, 1.5)*Vector2.ONE
		spark_instance.dir = Vector2.from_angle(spawn_rotate+PI/2+randf_range(-PI/2,PI/2))
		spark_instance.speed = randf_range(1,3)*SPEED
		spark_instance.damage/=spawn_scale
		spark_instance.init(card_type, card_name)
		$SparkPoint.add_child(spark_instance)
