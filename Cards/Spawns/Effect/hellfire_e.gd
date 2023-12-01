extends AnimatableBody2D

var damage = 10
var endpos: Vector2
var speed = 200


func _ready():
	damage = randi_range(10, 15)

func set_speed(speed_):
	speed = speed_

func set_endpos(endpos_):
	endpos = endpos_
	var time = randi_range(10, 50)
	position = -0.2*time*speed*Vector2.ONE+endpos

func _physics_process(delta):
	var collision = move_and_collide(speed*delta*Vector2.ONE)
	if collision or endpos<position:
		queue_free()
	
	apply_scale(Vector2.ONE*1.003)
	
	
