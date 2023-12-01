extends Player

func animation_func(direction):
	super(direction)
	if direction:
		direction.y*=-1
		$Sprite2D/AnimationPlayer/AnimationTree.set("parameters/TimeScale/scale", 1)
		$Sprite2D/AnimationPlayer/AnimationTree.set("parameters/BlendSpace2D/blend_position", direction)
	else:
		$Sprite2D/AnimationPlayer/AnimationTree.set("parameters/TimeScale/scale", 0)


func destroy_card_func():
	super()
	if !$Sprite2D/AnimationPlayer/AnimationTree.get("parameters/OneShot/active"):
			$Sprite2D/AnimationPlayer/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func destroy_card_cancel():
	super()
	card_under_modulate = Color.WHITE
	$Sprite2D/AnimationPlayer/AnimationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

func on_health_depleted():
	super()
	if !$Sprite2D/AnimationPlayer/AnimationTree.get("parameters/OneShot 2/active"):
			$Sprite2D/AnimationPlayer/AnimationTree.set("parameters/OneShot 2/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func take_damage(damage: float):
	super(damage)
	if damage>0:
		for i in range(16):
			var spike = $Spike.duplicate()
			spike.init(card_type, card_name)
			spike.scale = Vector2.ZERO
			spike.position = position
			get_parent().add_child.call_deferred(spike)
			spike.rotation = i*PI/8
			spike.global_scale = global_scale
			spike.damage = damage
			spike.dir = Vector2.ONE.rotated(spike.rotation)

	
func _on_hitbox_body_entered(body):
	if not("card_name" in body and "card_type" in body and body.card_type == "Player" and body.card_name == "Ghoul"):
		super(body)
