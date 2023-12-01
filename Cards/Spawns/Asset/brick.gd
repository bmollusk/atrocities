extends SyncedAsset



var SPEED = 50
func _ready():
	super()
	$Sprite2D/AnimationPlayer.play("default")
	dir = Vector2.DOWN.rotated(spawn_rotate)
	SPEED*=spawn_scale
	if (asset_owner==multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER) or Globals.game_mode == Globals.modes.AI:
		$Timer.start()

func _physics_process(delta):
	if ((asset_owner==multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER) or Globals.game_mode == Globals.modes.AI) \
	and fullyspawned: 
		var collision = move_and_collide(dir*delta*SPEED)
	super(delta)


func _on_timer_timeout():
	new_dir(Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized())
	fire.rpc()

func new_dir(dir_: Vector2):
	dir = dir_

@rpc("any_peer", "call_local")
func fire():
	for i in range(8):
		var zap = $Zap.duplicate()
		zap.init(card_type, card_name)
		zap.scale = Vector2.ZERO
		zap.position = position
		get_parent().add_child.call_deferred(zap)
		zap.rotation = i*PI/4
		zap.global_scale = global_scale
		zap.dir = Vector2.DOWN.rotated(zap.rotation)

func hitbox_entered(player):
	dir = player.global_position.direction_to(global_position)
