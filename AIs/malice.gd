extends GameAI




func make_decision():
	if get_playable_hand().size()<=2 and can_activate and not Globals.active:
		activate()
		return
	
	if play_card_func.is_null():
		return
	if place_card_func.is_null():
		return

	if not can_activate:
		var has_player = false
		for card in get_playable_hand():
			if card[0]=="Player":
				has_player = true
				
		if not has_player and hand.size()<Globals.HANDSIZE and deck.size()>0:
			draw_card()
			await get_tree().create_timer(.4).timeout
	if get_playable_hand().size()>0:
		var pickedcard = get_playable_hand().pick_random()
		var tags = Globals.get_tags(pickedcard)
		if Globals.tags.pick_table_card in tags and Globals.tags.delete_card in tags:
			if hand.size()==1:
				activate()
			else:
				decision_made.emit()
			return
		play_card(pickedcard)
		await get_tree().create_timer(0.8).timeout
		var target = player_placed_cards.pick_random()
		var position_: Vector2
		var scale_ = Vector2.ONE
		var rotation_ = 0
		if pickedcard[0]=="Player":
			can_activate = true
			if Globals.table_bounds.get_center().distance_to(target["position"])>50:
				position_ = Globals.snap_pos(Globals.flip_pos(target["position"]))
			else:
				position_ = target["position"]
				position_.x -= 100
				position_ = Globals.snap_pos(position_)
			while check_intersect(position_):
				position_ = table_random_pos()
			while position_.distance_to(target["position"]) >75 and check_in_table(position_) and not check_intersect(position_):
				position_ = position_.move_toward(target["position"], 10)
			position_ = Globals.snap_pos(position_)
			rotation_ = 0
			scale_ = Vector2.ONE
		elif pickedcard[0]=="Asset":
			position_ = table_random_pos()
			while check_intersect(position_):
				position_ = table_random_pos()
			if (Globals.tags.projectile in tags or Globals.tags.spread in tags) \
				and Globals.tags.table_range not in tags and Globals.tags.healing not in tags:
				var rotation_vector = position_.direction_to(target["position"])
				rotation_ = Globals.snap_rot(Vector2.DOWN.angle_to(rotation_vector))
				var dist
				if Globals.tags.card_range in tags:
					dist = 20
				elif Globals.tags.low_range in tags:
					dist = 40
				elif Globals.tags.medium_range in tags:
					dist = 60
				elif Globals.tags.high_range in tags:
					dist = 80
				while position_.distance_to(target["position"]) > dist and check_in_table(position_) and not check_intersect(position_):
					position_= position_.move_toward(target["position"], 15)
			
			position_ = Globals.snap_pos(position_)
			scale_ = Globals.snap_scale(randf_range(Globals.MIN_SCALE,Globals.MAX_SCALE))*Vector2.ONE
		else:
			var test_pos = table_random_pos()
			while check_intersect(test_pos):
				test_pos = table_random_pos()
			position_ = Globals.snap_pos(test_pos)
			
		place_card(pickedcard, position_, scale_, rotation_)
		await get_tree().create_timer(1).timeout
		
		decision_made.emit()

func start_play(play_card_func_: Callable):
	super(play_card_func_)
	if player_placed_cards.size()>0:
		timer_start()

func _on_decision_made():
	timer_start()

func player_place_card(type, cardname, position_, scale_, rotation_):
	super(type, cardname, position_, scale_, rotation_)
	timer_start(decision_time, decision_time_variance)	
