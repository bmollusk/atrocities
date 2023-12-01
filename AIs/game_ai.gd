extends Node2D

class_name GameAI

@export var decision_time:float = 2
@export var decision_time_variance:float = 1
@export var ai_controller: AIController

var deck = []
var hand = []

var placed_cards = []
var pickedplayer

var deal_func: Callable
var deck_ui_func: Callable
var draw_card_func: Callable
var play_card_func: Callable
var place_card_func: Callable

var player_deck_len = 0
var player_hand_len = 0

var player_placed_cards = []

var DECISIONTIMER: Timer

var can_activate = false
signal decision_made



func _ready():
	DECISIONTIMER = $DecisionTimer
	
	

func pick_deck(deck_ind: int, deck_pick_func: Callable):
	var choices = [0,1,2]
	choices.erase(deck_ind)
	await get_tree().create_timer(1).timeout
	deck_pick_func.call(choices.pick_random())

func load_deck(deck_: Array, deck_ui_func_: Callable):
	deck = deck_
	deck_ui_func = deck_ui_func_
	for i in range(1,len(deck)+1):
		deck_ui_func.call(i)
		await get_tree().create_timer(0.1).timeout

func start_turn(draw_card_func_: Callable):
	DECISIONTIMER.stop()
	for i in range(min(Globals.HANDSIZE-len(hand), len(deck))):
		draw_card_func = draw_card_func_
		draw_card()
		await get_tree().create_timer(.4).timeout
	print(hand)

func draw_card():
	var card = deal_func.call(deck)
	draw_card_func.call(card)
	deck_ui_func.call(len(deck))
	await get_tree().create_timer(0.1).timeout
	hand.append(card)

func start_play(play_card_func_: Callable):
	play_card_func = play_card_func_

func timer_start(time = decision_time, time_variance = decision_time_variance):
	var lower  = clampf(time-time_variance, 0.1, 20)
	var upper  = clampf(time+time_variance, 0.1, 20) 
	DECISIONTIMER.start(randf_range(lower, upper))
	

func player_place_card(type, cardname, position_:Vector2, scale_:Vector2, rotation_: float):
	player_placed_cards.append({
		"type":type, 
		"cardname":cardname, 
		"position":Globals.flip_pos(position_), 
		"scale": scale_, 
		"rotation": rotation_+PI
		})

func player_remove_card(type, cardname, position_:Vector2, scale_:Vector2, rotation_: float):
	for card in player_placed_cards:
		if card["type"]==type and card["cardname"]==cardname \
		and Globals.flip_pos(position_).is_equal_approx(card["position"]) \
		and scale_.is_equal_approx(card["scale"]) and \
		is_equal_approx(rotation_+PI,card["rotation"]):
			player_placed_cards.erase(card)

func make_decision():
	if hand.size()==0:
		return
	if play_card_func.is_null():
		return
	if place_card_func.is_null():
		return
		
	var pickedcard;
	for card in hand:
		if card[0]=="Player":
			pickedcard = card
			break
	play_card(pickedcard)
	await get_tree().create_timer(0.5).timeout
	var position_ = Globals.table_bounds.get_center()+Vector2.ONE*randf()*10
	var scale_ = Vector2.ONE
	var rotation_ = 0
	place_card(pickedcard, position_, scale_, rotation_)
	await get_tree().create_timer(1).timeout
	activate()
	
	decision_made.emit()

func get_playable_hand():
	var playable_hand = []
	for card in hand:
		if card[0] == "Player" and not Globals.active:
			playable_hand.append(card)
		elif card[0] == "Effect" and Globals.active:
			playable_hand.append(card)
		elif card[0] == "Asset":
			playable_hand.append(card)
	return playable_hand

func play_card(pickedcard):
	hand.erase(pickedcard)
	play_card_func.call(pickedcard[0], pickedcard[1])

func place_card(pickedcard: Array, position_: Vector2, scale_: Vector2, rotation_: float):
	placed_cards.append({
		"type":pickedcard[0], 
		"cardname":pickedcard[1], 
		"position":position_, 
		"scale": scale_, 
		"rotation": rotation_
		})
	place_card_func.call(pickedcard[0], pickedcard[1], 
	position_, scale_, rotation_, 1)

func activate():
	Globals.activate_recieve()

func _on_decision_timer_timeout():
	make_decision()


func _on_decision_made():
#	timer_start()
	pass

func table_random_pos():
	var rand_pos = Vector2(
		randf_range(Globals.table_bounds.position.x, Globals.table_bounds.end.x),
		randf_range(Globals.table_bounds.position.y, Globals.table_bounds.end.y),
	)
	return rand_pos

func check_intersect(test_pos):
	var all_cards = placed_cards+player_placed_cards
	for card in all_cards:
		var rect1: Rect2 = card_rect(card)
		var rect2: Rect2 = pos_rect(test_pos)
		if rect1.intersects(rect2):
			return true
	return false
	
func check_in_table(test_pos):
	return Globals.table_bounds.has_point(test_pos)

func card_rect(card):
	return pos_rect(card["position"])

func pos_rect(pos):
	var size = 110
	return Rect2(
			pos.x-size/2, 
			pos.y-size/2,
			size,size
			)

