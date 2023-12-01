extends Asset

var speedable = {}

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	super(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id)
	apply_scale(spawn_scale*Vector2.ONE)

func _ready():
	super()
	$AnimationPlayer.play("hypno")

func add(body):
	if  "SPEED" in body or "speed" in body:
		if body.name in speedable:
			speedable[body.name][1]+=1
		else:
			speedable[body.name]=[body,1]
			$AnimationPlayer.play("hypno",-1,0.5)
		print(speedable)
	if "SPEED" in body:
		body.SPEED/=2
	if "speed" in body:
		body.speed/=2

func remove(body):
	if body.name in speedable:
		speedable[body.name][1]-=1
		if is_instance_valid(speedable[body.name][0]):
			if "SPEED" in body:
				speedable[body.name][0].SPEED*=2
			else:
				speedable[body.name][0].speed*=2
		if speedable[body.name][1]==0:
			speedable.erase(body.name)
			if speedable.size()==0:
				$AnimationPlayer.play("hypno")
		print(speedable)


func _on_area_body_entered(body):
	add(body)


func _on_area_body_exited(body):
	remove(body)
