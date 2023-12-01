extends IngameCard

var to_heal: Array[Node2D]
var timepassed = 0
var healamount = -5

func _on_area_2d_body_entered(body):
	super(body)
	if card_visible and "take_damage" in body:
		to_heal.append(body)

func _on_area_2d_body_exited(body):
	super(body)
	if body in to_heal:
		to_heal.erase(body)

func _process(delta):
	super(delta)
	if active:
		timepassed+=delta
#		print(timepassed)
	if timepassed>1:
		if rotation-PI/2<.01 or rotation-3*PI/2<0.1:
			for body in to_heal:
				if "groveboost" in body and body.groveboost:
					body.take_damage(healamount*scale.x)
				else:
					body.take_damage(2*healamount*scale.x)
		else:
			for body in to_heal:
				if "groveboost" in body and body.groveboost:
					body.take_damage(2*healamount*scale.x)
				else:
					body.take_damage(healamount*scale.x)
		
		timepassed=0
