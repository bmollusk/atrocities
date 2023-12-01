extends Player

var dir: Vector2
var targets = []

func _ready():
	super()
	dir = Vector2.DOWN.rotated(spawn_rotate)

func animation_func(direction: Vector2):
	if direction:
		$Sprite2D/AnimationPlayer.play("walk")
		dir = direction
	elif $Sprite2D/AnimationPlayer.assigned_animation=="walk":
		$Sprite2D/AnimationPlayer.play("idle")



func _on_sprite_2d_frame_changed():
	if $Sprite2D/AnimationPlayer.assigned_animation != "destroy":
		var y = Globals.rotation_to_frame_coords(Vector2.DOWN.angle_to(dir),0)
		if $Sprite2D.frame_coords.y!=y:
			$Sprite2D.frame_coords.y=y

func destroy_card_func():
	super()
	if cards_under.size()>0:
		if $Sprite2D/AnimationPlayer.assigned_animation != "destroy":
				$Sprite2D/AnimationPlayer.play("destroy")
	if targets.size()>0:
		var hand: Projectile = $Hand.duplicate()
		hand.init(card_type, card_name)
		hand.scale = Vector2.ZERO
		hand.position = position
		hand.dir = position.direction_to(targets[-1].position)
		get_parent().add_child(hand)
		hand.global_scale = global_scale

func on_health_depleted():
	super()
	$Sprite2D/AnimationPlayer.play("death")

func _on_hitbox_body_entered(body):
	if not("card_name" in body and "card_type" in body and body.card_type == card_type and body.card_name == card_name):
		super(body)

func _on_area_2d_body_entered(body):
	if body is Player and not body == self:
		targets.append(body)
		$Hand.visible = true
		$Hand.position = position+position.direction_to(targets[-1].position)*10


func _on_area_2d_body_exited(body):
	if body in targets:
		targets.erase(body)
	if targets.size()!=0:
		$Hand.position = position+position.direction_to(targets[-1].position)*10
	else:
		$Hand.visible = false
		$Hand.position = position
