extends Asset

var SPEED = 70
var damage = 20
var dir: Vector2
var clone_id = 0
var angle = PI/8
var max_clone = 4
func _ready():
	super()
	if clone_id>0:
		$Sprite2D/AnimationPlayer.play("decay", -1, 0.5)
		$AudioStreamPlayer2D.play()
		max_clone = int(max_clone*spawn_scale)
		$CloneTimer.start()

func on_spawned():
	super()
	if clone_id==0:
		dir = Vector2.DOWN.rotated(spawn_rotate - angle*max_clone/2)
	$Sprite2D/AnimationPlayer.play("decay", -1, 0.5)
	max_clone = int(max_clone*spawn_scale)
	set_collision_layer_value(4, true)
	$CloneTimer.start()
	

func _physics_process(delta):
	if fullyspawned:
		move_and_collide(dir*delta*SPEED)
	

func hitbox_entered(player):
	destroy()


func _on_clone_timer_timeout():
	if clone_id<max_clone:
		clone()
	else:
		$CloneTimer.stop()
		

func clone():
	print(clone_id, dir, position, dir.rotated(PI/2))
	var alien: Asset = duplicate()
	alien.dir=dir.rotated(angle)
	alien.global_position=position+dir*2
	alien.clone_id=clone_id+1
	alien.visible=true
	alien.fullyspawned=true
	alien.init(card, card_type, card_name, spawn_scale, spawn_rotate, spawn_translate, asset_owner)
	get_parent().add_child(alien)
	


func _on_animation_player_animation_finished(anim_name):
	if clone_id<max_clone-1:
		queue_free()
	else:
		destroy()
