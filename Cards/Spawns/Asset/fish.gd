extends Asset

var dir = Vector2.UP
var gravity = 0
var grav_acc = 0.15
var maxAge = 1.5
var SPEED = 200
var age = 0
var damage = 10
var rot
func _ready():
	super()
	rot = randf_range(0,2*PI)
	var y = Globals.rotation_to_frame_coords(rot,0)
	$Sprite2D.frame_coords.y=y
	
func on_spawned():
	super()
	dir+=Vector2.DOWN.rotated(rot)
	dir=dir.normalized()
	$Sprite2D/AnimationPlayer.play("fish")
	maxAge*=spawn_scale
	set_collision_layer_value(4, true)
	
func _on_sprite_2d_frame_changed():
	var y = Globals.rotation_to_frame_coords(rot,0)
	if $Sprite2D.frame_coords.y!=y:
		$Sprite2D.frame_coords.y=y
	
func _physics_process(delta):
	if age>maxAge:
		destroy()
		$AudioStreamPlayer2D.play()
	if fullyspawned:
		move_and_collide(dir*delta*SPEED+gravity*Vector2.DOWN)
		gravity+=grav_acc
		age += delta
