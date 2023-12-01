extends Player

var bodies = []
var tween: Tween
var hand_scale = Vector2(2.288, 1.091)
var dir: Vector2

func _ready():
	super()
	$Sprite2D/AnimationPlayer.play("idle")

func animation_func(direction):
	super(direction)

	if direction:
		if $Sprite2D/AnimationPlayer.assigned_animation != "walk":
			$Sprite2D/AnimationPlayer.play("walk")
		dir = direction
	elif $Sprite2D/AnimationPlayer.assigned_animation=="walk":
		$Sprite2D/AnimationPlayer.play("idle")
#		if not tween or not tween.is_running():
#			tween = create_tween()
#			tween.tween_property($Hand, "modulate", Color($Hand.modulate, 0),2)
#			tween.parallel().tween_property($Hand, "scale", hand_scale, 3)
#			tween.tween_property($Hand, "modulate", Color($Hand.modulate, 1), 5)
#			tween.parallel().tween_property($Hand, "scale", 0.9*hand_scale, 5)
##			tween.parallel().tween_method($Hand.apply_scale, Vector2.ONE*0.9, Vector2.ONE*0.9, 5)
#			tween.tween_callback(hand_damage)
		
func _on_sprite_2d_frame_changed():
	var y = Globals.rotation_to_frame_coords(Vector2.DOWN.angle_to(dir),0)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y

func destroy_card_func():
	super()
	if $Sprite2D/AnimationPlayer.assigned_animation != "destroy" or not $Sprite2D/AnimationPlayer.is_playing():
			$Sprite2D/AnimationPlayer.play("destroy")
	
func on_health_depleted():
	super()
	$Sprite2D/AnimationPlayer.play("death")
	

func hand_damage():
	for body in bodies:
		if body != self:
			body.take_damage(5)

func self_hand_damage():
	for body in bodies:
		if body == self:
			body.take_damage(1)



func _on_area_2d_body_entered(body):
	print(body)
	if "take_damage" in body:
		bodies.append(body)


func _on_area_2d_body_exited(body):
	if body in bodies:
		bodies.erase(body)
