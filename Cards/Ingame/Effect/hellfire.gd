extends IngameCard

func default_ingame_shown_func(ingame: Node2D):
	$AudioStreamPlayer.play()
	var spawn = ingame.find_child("Spawns")
	var hellfirespawn = preload("res://Cards/Spawns/Effect/hellfire_e.tscn")
	var bounds = Globals.table_bounds
	var num = randi_range(20*scale.x, 40*scale.x)
	var fixedrot = Globals.if_norot(rotation, card_owner)
	fixedrot = Globals.fix_neg_rot(fixedrot)
	for i in range(num):
		var star = hellfirespawn.instantiate()
		var endpos = Vector2(randi_range(bounds.position.x-Globals.margin.x, bounds.end.x+Globals.margin.x),\
		 randi_range(bounds.position.y-Globals.margin.y, bounds.end.y+Globals.margin.y))
		var speed = remap(fixedrot, 0, 2*PI, 200, 400)
		star.set_speed(speed)
		star.set_endpos(endpos)
		spawn.add_child(star)

func _on_area_2d_body_entered(body):
	if not card_visible:
		open_eye()
	else:
		body.entered_card(self)
		card_entered()
