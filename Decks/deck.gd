extends Area2D

class_name Deck

@export var deck: Array

var p2 = false
var gone = false

var fullyspawned = false
signal picked
	
static func gen_deck(decksize: int=50):
	var deck_ = []
	var picklist = []
	var justplayers = []
	for card in Globals.cards:
		for i in range(Globals.cards[card]):
			picklist.append(card)
			if card.begins_with("Player"):
				justplayers.append(card)
	var frontplayer = justplayers.pick_random()
	var frontcard: Array = Globals.card_str_to_arr(frontplayer)
	deck_.append(frontcard)
	for i in range(decksize-2):
		if i==floor((decksize-2)/2)-1 or i==floor((decksize-2)/2):
			var middleplayer = justplayers.pick_random()
			var middlecard: Array = Globals.card_str_to_arr(middleplayer)
			deck_.append(middlecard)
		else:
			var cardstring: String = picklist.pick_random()
			var card: Array = Globals.card_str_to_arr(cardstring)
			deck_.append(card)
	var backplayer = justplayers.pick_random()
	var backcard: Array = Globals.card_str_to_arr(backplayer)
	deck_.append(backcard)
	print(deck_)
	return deck_

func init(deck_, color):
	deck = deck_
	$Sprite2D.modulate = color 

func _ready():
	$Sprite2D/AnimationPlayer.play("deckspawn")
	

func _process(_delta):
	var multiplayer_condition = (not p2 and multiplayer.get_unique_id()==Globals.P1) or (p2 and multiplayer.get_unique_id()!=Globals.P1)
	multiplayer_condition = multiplayer_condition and Globals.game_mode == Globals.modes.MULTIPLAYER
	var ai_condition = not p2 and Globals.game_mode == Globals.modes.AI
	if multiplayer_condition or ai_condition:
		$Sprite2D.position = Vector2(randf_range(-1,1),randf_range(-1,1))


func _on_animation_player_animation_finished(anim_name):
	if anim_name=="deckspawn":
		fullyspawned = true


func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event.is_action_pressed("Action") and fullyspawned:
		var multiplayer_condition = (not p2 and multiplayer.get_unique_id()==Globals.P1) or (p2 and multiplayer.get_unique_id()!=Globals.P1)
		multiplayer_condition = multiplayer_condition and Globals.game_mode == Globals.modes.MULTIPLAYER
		var ai_condition = not p2 and Globals.game_mode == Globals.modes.AI 
		if multiplayer_condition or ai_condition:
			picked.emit()

func pick():
	$Sprite2D/AnimationPlayer.play("deckdespawn")

func deck_picked():
	gone = true
	queue_free()


func _on_mouse_entered():
	var multiplayer_condition = (not p2 and multiplayer.get_unique_id()==Globals.P1) or (p2 and multiplayer.get_unique_id()!=Globals.P1)
	multiplayer_condition = multiplayer_condition and Globals.game_mode == Globals.modes.MULTIPLAYER
	var ai_condition = not p2 and Globals.game_mode == Globals.modes.AI
	if ai_condition or multiplayer_condition:
		Globals.cursor_state = Globals.cursor_states.HOVER


func _on_mouse_exited():
	Globals.cursor_state = Globals.cursor_states.DEFAULT
