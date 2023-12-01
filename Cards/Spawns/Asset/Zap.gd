extends Projectile

var SPEED = 100

func _physics_process(delta):
	super(delta)
	if dir:
		move_and_collide(dir*SPEED*delta)
