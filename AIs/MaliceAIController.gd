extends AIController

var card_is_destroyed = false
const OFFSET = Vector2(0,-10)

func init_info(playerspawn: Player):
	super(playerspawn)
	scoreeqs = {
			Globals.tags.healing: 10,
			Globals.tags.damaging: 12,
			Globals.tags.strong: 20,
			Globals.tags.super_strong: 30,
			Globals.tags.projectile: 40,
			Globals.tags.spread: 30,
			Globals.tags.on_contact: 15,
			Globals.tags.on_timer: 10,
		}
	var cards = ai_parent.player_placed_cards
	for card in cards:
		var str = Globals.card_arr_to_str([card['type'], card['cardname']])
		if card['type']=="Player":
			add_stop(str, 10, Globals.flip_pos(card['position']))
	
	playerspawn.card_destroyed.connect(card_destroyed)
	playerspawn.destroyed.connect(destroyed)
func get_vector()->Vector2:
	var vector: Vector2
	for area in areas_visible:
		var card = area.get_parent()
		if card is IngameCard:
			var str = Globals.card_arr_to_str([card.card_type, card.card_name])
			if str in stops:
				if card.card_visible:
					stops[str][1] = card.global_position
				else:
					stops[str][0] = 5
			if str not in stops and str in Globals.ai_tags and Globals.tags.healing in Globals.ai_tags[str]:
				add_stop(str, 0, card.position)
	if player.HEALTH<10:
		for str in stops:
			if str in Globals.ai_tags and Globals.tags.healing in Globals.ai_tags[str]:
				stops[str][0] = 15
	if stops.size()>0:
		var max_score = stops.values().reduce(func(accum, value): return value if value[0]>accum[0] else accum)
		var goal = max_score[1]
		var path = astar_grid.calculate_point_path(global_position,goal)
		if path.size()>1:
#			print(global_position, " ", path)
			vector = global_position.direction_to(path[1])
		else:
			vector = global_position.direction_to(goal)
		if global_position.distance_to(goal)<5:
			var key = stops.find_key(max_score)
			if Globals.card_str_to_arr(key)[0]=="Player" and player.HEALTH>5:
				if not card_is_destroyed:
					vector = Vector2()
					destroy_key = true
				else:
					card_is_destroyed = false
					stops.erase(key)
		else:
			destroy_key = false
	var points:Array[Vector2i]
	for body in bodies_visible:
		points+=astar_grid.get_id_list_inside_circle(body.global_position, 2)
		if global_position.distance_to(body.global_position)<20 and body != player and "damage" in body:
			if "dir" in body:
				vector += body.dir.orthogonal()
		if "card_type" in body and "card_name" in body\
		 	and Globals.card_arr_to_str([body.card_type, body.card_name]) in Globals.ai_tags \
			and Globals.tags.homing in Globals.ai_tags[Globals.card_arr_to_str([body.card_type, body.card_name])]:
			vector += body.global_position.direction_to(global_position)*2
		if body is Player and body!=player and not destroy_key and not player.cards_under.size()>0:
			if player.card_name == "Bodies":
				vector +=  global_position.direction_to(body.global_position).orthogonal()*0.5
			if player.card_name == "Enemy":
				if global_position.distance_to(body.global_position)>20:
					destroy_key = false
					vector += global_position.direction_to(body.global_position)
				else:
					vector = Vector2.ZERO
					destroy_key = true
			if player.card_name == "Wastoid":
				destroy_key = true
	astar_grid.set_disabled_points(points)
	vector = vector.normalized()
	return vector

func _on_visible_area_body_exited(body):
	super(body)
	if player and is_instance_valid(player):
		if player.card_name == "Enemy" and destroy_key and body is Player and player.cards_under.size()==0:
			destroy_key = false
		if player.card_name == "Wastoid" and destroy_key and body is Player and player.cards_under.size()==0:
			destroy_key = false

func card_destroyed():
	card_is_destroyed = true
	destroy_key = false

func destroyed():
	destroy_key = false
