extends SyncedAsset

var damage_tween: Tween

@export var SPEED = 200

var BASEHEALTH = 75
var HEALTH = BASEHEALTH:
	set(value):
		HEALTH = value
		if multiplayer and asset_owner == multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER:
			sync_health.rpc(value)
			if value <= 0:
				on_health_depleted.rpc()
		elif Globals.game_mode == Globals.modes.AI:
			if value<=0:
				on_health_depleted()
	get:
		return HEALTH

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	super(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id)
	apply_scale(spawn_scale*Vector2.ONE)
	dir = Vector2.DOWN.rotated(spawn_rotate)


func _ready():
	super()
	var y = Globals.rotation_to_frame_coords(spawn_rotate,0)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y
	HEALTH = BASEHEALTH*spawn_scale
	
func on_spawned():
	super()
	$Sprite2D/AnimationPlayer.play("drive")
	if (asset_owner==multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER) or Globals.game_mode == Globals.modes.AI:
		$Timer.start()
	$Wheel.play()


func _on_sprite_2d_frame_changed():
	var y = Globals.rotation_to_frame_coords(Vector2.DOWN.angle_to(dir),0)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y

func _physics_process(delta):
	if (asset_owner==multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER) or Globals.game_mode == Globals.modes.AI:
		var collision = move_and_collide(delta*SPEED*dir)
		if collision:
			dir = dir.bounce(collision.get_normal())
#		if fullyspawned and HEALTH>0:
#			take_damage(5)
	super(delta)
	

func _on_timer_timeout():
	dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

@rpc("any_peer","call_remote")
func sync_health(health):
	HEALTH = health

func _on_hitbox_body_entered(body):
	if "damage" in body and fullyspawned:
		if damage_tween and damage_tween.is_valid() and damage_tween.is_running():
			damage_tween.kill()
		damage_tween = create_tween()
		var percent_health = remap(HEALTH, 0, BASEHEALTH*spawn_scale, 0, 1)
		damage_tween.tween_property(SPRITE, "modulate", \
		Color(1, percent_health, percent_health), 0.1)\
		.from(Color.CRIMSON)
		print(body.damage)
		if HEALTH>0:
			take_damage(body.damage)
	if "hitbox_entered" in body and fullyspawned:
		body.hitbox_entered(self)

func take_damage(damage: float):
	if HEALTH-damage>BASEHEALTH*spawn_scale:
		return 
	if (asset_owner==multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER) or Globals.game_mode == Globals.modes.AI:
		HEALTH-=damage

@rpc("any_peer", "call_local")
func on_health_depleted():
	$Explosion.visible = true
	$Explosion.set_collision_layer_value(4, true)
	$Explosion.init(card_type, card_name)
	$Explode.play()
	$Wheel.stop()
	$Sprite2D/AnimationPlayer.play("explosion")
