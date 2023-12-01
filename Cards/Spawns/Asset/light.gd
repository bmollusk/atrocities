extends Asset

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	super(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id)
	apply_scale(spawn_scale*Vector2.ONE)
	$RayCast2D.rotation = spawn_rotate
	$RayCast2D.target_position.y*=spawn_scale

func on_spawned():
	super()
	$AudioStreamPlayer2D.play()


func _physics_process(delta):
	if fullyspawned:
		$RayCast2D.force_raycast_update()
		if $RayCast2D.is_colliding():
			$RayCast2D/Line2D.points[1] = Vector2(0,$RayCast2D.position.distance_to(to_local($RayCast2D.get_collision_point())))
			var body = $RayCast2D.get_collider().get_parent()
			if "take_damage" in body:
				body.take_damage(1)
		else:
			$RayCast2D/Line2D.points[1] = $RayCast2D.target_position
		$RayCast2D.rotate(delta)

