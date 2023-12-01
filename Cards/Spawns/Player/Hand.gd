extends Projectile

var SPEED = 300

func init(type, cardname):
	super(type, cardname)
	if visible:
		$AnimationPlayer.play("default")

func _physics_process(delta):
	super(delta)
	if dir:
		move_and_collide(dir*SPEED*delta)
