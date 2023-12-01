extends Asset

var SPEED = 200

var targets = []
var opentexture = load("res://Cards/Spawns/Asset/Images/eye.png")
var closedtexture = load("res://Cards/Spawns/Asset/Images/eyeclosed.png")
var eye: Sprite2D

var norot = true

func _ready():
	super()
	var y = Globals.rotation_to_frame_coords(spawn_rotate, 0)
	$Sprite2D.frame_coords.x = y
	$Timer.wait_time*spawn_scale


func _physics_process(delta):
	for tear in $Projectiles.get_children():
		tear.move_and_collide(tear.dir*SPEED*delta)


func _on_attack_radius_area_entered(area):
	targets.append(area)




func _on_timer_timeout():
	if eye:
		eye.texture = opentexture
	if len(targets)>0:
		var target: Area2D = targets[-1]
		eye = $Eyes.get_children().pick_random()
		eye.texture = closedtexture
		var rand_pos: Vector2 = eye.position
		var tear: Projectile  = $Tear.duplicate()
		tear.damage*=spawn_scale
		tear.scale = spawn_scale*Vector2.ONE
		tear.position = rand_pos
		tear.dir = eye.global_position.direction_to(target.global_position+Vector2.UP*randf_range(10, 20))
		tear.init(card_type, card_name)
		$Projectiles.add_child(tear)


func _on_attack_radius_area_exited(area):
	targets.erase(area)
