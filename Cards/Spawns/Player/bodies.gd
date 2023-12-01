extends Player

var groveboost = true

func animation_func(direction):
	super(direction)
	if direction:
		$Sprite2D/AnimationPlayer.play("walk")
	elif $Sprite2D/AnimationPlayer.assigned_animation == "walk":
		$Sprite2D/AnimationPlayer.pause()

func destroy_card_func():
	super()
	if $Sprite2D/AnimationPlayer.assigned_animation != "destroy":
			$Sprite2D/AnimationPlayer.play("destroy", -1, 0.25)
	else:
		$Sprite2D/AnimationPlayer.advance(0.01)


func _on_animation_player_animation_finished(anim_name):
	if anim_name=="Destroy":
		$Sprite2D/AnimationPlayer.play("walk")

func on_health_depleted():
	super()
	$Sprite2D/AnimationPlayer.play("death")


func _on_sprite_2d_frame_changed():
	$Trail/Sprite2D.frame = $Sprite2D.frame
	var trail = $Trail.duplicate()
	trail.init(card_type, card_name)
	trail.scale = Vector2.ZERO
	trail.position = position
	get_parent().add_child(trail)
	trail.global_scale = global_scale
	
func _on_hitbox_body_entered(body):
	if not("card_name" in body and "card_type" in body and body.card_type == card_type and body.card_name == card_name):
		super(body)
