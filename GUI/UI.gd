extends Control

@export var debug = false

var deck = []

var decksize = 25


signal played(type, cardname, ingame_play_func:Callable)



var past:Dictionary

var CANVASLAYER
var ACTIVETIMER: Timer
var ACTIVATEBUTTON: TextureButton
var button_normal_texture: Texture2D
var button_hover_texture: Texture2D
var button_disabled_noplayer_texture: Texture2D
var button_disabled_texture: Texture2D
var button_other_texture: Texture2D
var button_other_hover_texture: Texture2D

var PROGRESSBAR: TextureProgressBar
var DECKAMOUNT: RichTextLabel
var DECKIMAGE: TextureButton
var OTHERDECKAMOUNT: RichTextLabel
var OTHERDECKIMAGE: TextureRect

var HAND: MarginContainer
var HANDCONTAINER: HBoxContainer
var OTHERHAND: MarginContainer
var OTHERHANDCONTAINER: HBoxContainer

var MODALTEXTURE: TextureRect
var MODAL: MarginContainer
var DRAWCARDAUDIO: AudioStreamPlayer2D

const DUMMYCOMPENSEY = Vector2(0,43)
const DUMMYCOMPENSEX = Vector2(-60,0)
const DUMMYCOMPENSEXY = DUMMYCOMPENSEX+DUMMYCOMPENSEY



@export var ai_node: GameAI

# Called when the node enters the scene tree for the first time.
func _ready():
#	if Globals.P1 == multiplayer.get_unique_id():
#		deck = deck2
		
	CANVASLAYER = $CanvasLayer
	
	ACTIVETIMER = $CanvasLayer/Deck/ActiveTimer
	ACTIVATEBUTTON = $CanvasLayer/Deck/ActivateButton
	
	PROGRESSBAR = $CanvasLayer/Deck/TextureProgressBar
	DECKAMOUNT = $CanvasLayer/Deck/VBoxContainer/DeckAmount
	DECKIMAGE = $CanvasLayer/Deck/VBoxContainer/DeckImage
	OTHERDECKIMAGE = $CanvasLayer/Deck/VBoxContainer2/DeckImage
	OTHERDECKAMOUNT = $CanvasLayer/Deck/VBoxContainer2/DeckAmount
	
	
	HAND = $CanvasLayer/Hand
	HANDCONTAINER = $CanvasLayer/Hand/HBoxContainer
	OTHERHAND = $CanvasLayer/OtherHand
	OTHERHANDCONTAINER = $CanvasLayer/OtherHand/HBoxContainer
	
	
	MODALTEXTURE = $CanvasLayer/Modal/ModalCard/TextureRect
	MODAL = $CanvasLayer/Modal
	
	DRAWCARDAUDIO = $DrawCardAudio
	
#	update_deck_ui()
#	update_deck_ui_remote.rpc(len(deck))
	Globals.activated.connect(on_activation)
	Globals.other_activated.connect(other_on_activation)
	Globals.deactivated.connect(on_deactivation)
	Globals.cursorchanged.connect(on_cursor_change)
	Globals.arm_state_change.connect(arm_disarm_activate_button)
	
	button_normal_texture = load("res://Cursors/{0}/Button{1}.png".format([Globals.cursor, "Normal"]))
	ACTIVATEBUTTON.set_texture_normal(button_normal_texture)
	button_hover_texture = load("res://Cursors/{0}/Button{1}.png".format([Globals.cursor, "Hover"]))
	ACTIVATEBUTTON.set_texture_hover(button_hover_texture)
	button_disabled_noplayer_texture = load("res://Cursors/{0}/Button{1}.png".format([Globals.cursor, "DisabledNoPlayer"]))
	ACTIVATEBUTTON.set_texture_disabled(button_disabled_noplayer_texture)
	
	button_disabled_texture = load("res://Cursors/{0}/Button{1}.png".format([Globals.cursor, "Disabled"]))
	button_other_texture = load("res://Cursors/{0}/Button{1}.png".format([Globals.cursor, "Other"]))
	button_other_hover_texture = load("res://Cursors/{0}/Button{1}.png".format([Globals.cursor, "OtherHover"]))

	Globals.game_end.connect(end_animation)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var progress = ACTIVETIMER.time_left/ACTIVETIMER.wait_time
	PROGRESSBAR.value = progress*100

func _on_table_load_deck(deck_: Array):
	if debug:
		deck = deck_
		update_deck_ui()
	else:
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			if Globals.P1 == multiplayer.get_unique_id():
				deck_ = deck_.slice(0, deck_.size()/2)
				deck_.reverse()
			else:
				deck_ = deck_.slice(deck_.size()/2, deck_.size())
		elif Globals.game_mode == Globals.modes.AI:
			var ai_deck = deck_.slice(deck_.size()/2, deck_.size())
			ai_node.load_deck(ai_deck, update_deck_ui_remote)
			ai_node.deal_func = default_deal
			deck_ = deck_.slice(0, deck_.size()/2)
			ai_node.player_deck_len = len(deck_)
			deck_.reverse()
		deck = []
		for card in deck_:
			deck.append(card)
			update_deck_ui()
			if Globals.game_mode == Globals.modes.MULTIPLAYER:
				update_deck_ui_remote.rpc(len(deck))
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(0.5).timeout
	start_turn()

@rpc("any_peer")
func update_deck_ui_remote(deckamount):
	var formattext
	formattext = "[center][shake rate={0} level={1} connected=1]{2}[/shake][/center]"
	var shake_rate = clampf(remap(deckamount,0,decksize,30,0),0,30)
	var shake_amount = clampf(remap(deckamount,0,decksize,15,0),0,15)
	OTHERDECKAMOUNT.text = formattext.format([shake_rate,shake_amount,deckamount])
	var imagenum = "%0*d" % [4, deckamount]
	var imagepath = "res://Overlays/Deck/DeckFrame/{0}.png".format([imagenum])
	OTHERDECKIMAGE.texture = load(imagepath)

func update_deck_ui():
	var formattext
	formattext = "[center][shake rate={0} level={1} connected=1]{2}[/shake][/center]" 
	var shake_rate = clampf(remap(len(deck),0,decksize,30,0),0,30)
	var shake_amount = clampf(remap(len(deck),0,decksize,15,0),0,15)
	DECKAMOUNT.text = formattext.format([shake_rate,shake_amount,len(deck)])
	var imagenum = "%0*d" % [4, len(deck)]
	var imagepath = "res://Overlays/Deck/DeckFrame/{0}.png".format([imagenum])
	DECKIMAGE.texture_normal = load(imagepath)

func tween_hand_on_child_removed(node: Container):
	if node.item_rect_changed.is_connected(tween_hand_on_child_removed):
		tween_multiple(node.get_children(), 0.06, Tween.EASE_OUT, Tween.TRANS_EXPO, DUMMYCOMPENSEY)
		node.item_rect_changed.disconnect(tween_hand_on_child_removed)

#func tween_hand_on_adjust_rect(node):
#	if HANDCONTAINER.item_rect_changed.is_connected(tween_hand_on_adjust_rect):
#		tween_multiple(node.get_children(), .1, Tween.EASE_OUT_IN, Tween.TRANS_QUAD)
#		HANDCONTAINER.item_rect_changed.disconnect(tween_hand_on_adjust_rect)

func tween_hand_on_child_entered(node: Container):
	if node.sort_children.is_connected(tween_hand_on_child_entered):
		tween_multiple(node.get_children(), .2, Tween.EASE_OUT, Tween.TRANS_EXPO, DUMMYCOMPENSEXY)
#		store_children_pasts(HANDCONTAINER)
#		HANDCONTAINER.item_rect_changed.connect(Callable(tween_hand_on_adjust_rect).bind(HANDCONTAINER))
		node.sort_children.disconnect(tween_hand_on_child_entered)
		

func tween_multiple(nodes: Array, duration, ease, trans, dummycompense):
	for node in nodes:
		tween(node, duration, ease, trans, dummycompense)
	
	
func tween(node, duration, ease, trans, dummycompense):
	if node.name in past:
		var present_transform: Transform2D = node.get_global_transform()
		var past_transform: Transform2D = past[node.name]
		var dummynode: Control = node.duplicate(0)
		node.visible = false
		dummynode.set_global_position(past_transform.get_origin()+dummycompense)
		CANVASLAYER.add_child(dummynode)
		
		var dummytween: Tween = create_tween()
		dummytween.set_parallel(true)
		dummytween.set_ease(ease)
		dummytween.set_trans(trans)
		dummytween.tween_method(dummynode.set_global_position,\
		past_transform.get_origin()+dummycompense,\
		present_transform.get_origin()+dummycompense,\
		duration)
#		dummytween.tween_property(dummynode, "rotation", present_transform.get_rotation(), 1)
#		dummytween.tween_property(dummynode, "scale", present_transform.get_scale(), 1)
		dummytween.set_parallel(false)
		dummytween.tween_callback(dummynode.queue_free)
		dummytween.tween_callback(func(): node.set_visible(true))
		past.erase(node.name)
		

func store_children_pasts(node):
	store_pasts(node.get_children())
	
func store_sibling_pasts(node):
	var siblings: Array = []
	for child in node.get_parent().get_children():
		if child!=node:
			siblings.append(child)
	store_pasts(siblings)

func store_pasts(nodes: Array):
	for node in nodes:
		store_past(node)

func store_past(node: Control):
	past[node.name] = node.get_global_transform()

func start_turn():
	lock_hand()
	if Globals.game_mode == Globals.modes.AI:
		ai_node.start_turn(draw_card_remote)
	for i in range(min(Globals.HANDSIZE-HANDCONTAINER.get_child_count(), len(deck))):
		draw_card(default_deal)
		update_deck_ui()
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			update_deck_ui_remote.rpc(len(deck))
		elif Globals.game_mode == Globals.modes.AI:
			ai_node.player_deck_len = len(deck)
		await get_tree().create_timer(.4).timeout
#	dealt.emit()
	if Globals.game_mode == Globals.modes.AI:
		ai_node.start_play(play_card_remote)
	
	unlock_hand()

func _on_deck_image_pressed():
	if Globals.HANDSIZE-HANDCONTAINER.get_child_count()>0 and len(deck)>0:
		draw_card(default_deal)
		update_deck_ui()
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			update_deck_ui_remote.rpc(len(deck))
		elif Globals.game_mode == Globals.modes.AI:
			ai_node.player_deck_len = len(deck)

func _on_deck_image_mouse_entered():
	if not DECKIMAGE.disabled:
		Globals.cursor_state = Globals.cursor_states.HOVER




func _on_deck_image_mouse_exited():
	if not DECKIMAGE.disabled:
		Globals.cursor_state = Globals.cursor_states.DEFAULT


func default_deal(deck_=deck):
	var card = deck_.pop_back()
	return card

@rpc("any_peer")
func draw_card_remote(card):
	var type:String = card[0]
	var cardname: String = card[1]
	var ui_card: UICard
	var specialcardpath = "res://Cards/UI/{0}/{1}.tscn".format([type,cardname.to_snake_case()])
	if ResourceLoader.exists(specialcardpath):
		ui_card = load(specialcardpath).instantiate()
	else:
		ui_card = preload("res://Cards/UI/ui_card.tscn").instantiate()
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		ui_card.init_card(type,cardname, multiplayer.get_remote_sender_id(), true)
	elif Globals.game_mode == Globals.modes.AI:
		ui_card.init_card(type,cardname, 1, true)
	OTHERHANDCONTAINER.add_child(ui_card)
	OTHERHANDCONTAINER.move_child(ui_card,0)
	var transform = ui_card.get_global_transform()
	transform.origin.x = 2000
	past[ui_card.name] = transform
	store_sibling_pasts(ui_card)
	OTHERHANDCONTAINER.sort_children.connect(Callable(tween_hand_on_child_entered).bind(OTHERHANDCONTAINER))

func draw_card(deal_func: Callable):
	DRAWCARDAUDIO.play(.6)
	var card = deal_func.call()
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		draw_card_remote.rpc(card)
	elif Globals.game_mode == Globals.modes.AI:
		ai_node.player_hand_len = HANDCONTAINER.get_child_count()+1
	var type:String = card[0]
	var cardname: String = card[1]
	var ui_card: UICard
	var specialcardpath = "res://Cards/UI/{0}/{1}.tscn".format([type,cardname.to_snake_case()])
	if ResourceLoader.exists(specialcardpath):
		ui_card = load(specialcardpath).instantiate()
	else:
		ui_card = preload("res://Cards/UI/ui_card.tscn").instantiate()
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		ui_card.init_card(type,cardname, multiplayer.get_unique_id())
	elif Globals.game_mode == Globals.modes.AI:
		ui_card.init_card(type,cardname, 0)
	ui_card.played.connect(Callable(play_card).bind(ui_card))
	ui_card.modal.connect(set_modal)
	HANDCONTAINER.add_child(ui_card)
	HANDCONTAINER.move_child(ui_card,0)
	var transform = ui_card.get_global_transform()
	transform.origin.x = 2000
	past[ui_card.name] = transform
	store_sibling_pasts(ui_card)
	HANDCONTAINER.sort_children.connect(Callable(tween_hand_on_child_entered).bind(HANDCONTAINER))	

func lock_hand():
	for card in HANDCONTAINER.get_children():
		card.lock()
	ACTIVATEBUTTON.disabled = true
	DECKIMAGE.disabled = true

func unlock_hand():
	for card in HANDCONTAINER.get_children():
		card.unlock()
	ACTIVATEBUTTON.disabled = !Globals.can_activate
	DECKIMAGE.disabled = false

@rpc("any_peer")
func play_card_remote(type, cardname):
	var ui_card: UICard
	for card in OTHERHANDCONTAINER.get_children():
		if card.card_name == cardname and card.card_type == type:
			ui_card = card
	OTHERHANDCONTAINER.item_rect_changed.connect(Callable(tween_hand_on_child_removed).bind(OTHERHANDCONTAINER))
	ui_card.queue_free()

func play_card(type, cardname, ui_play_func: Callable, ingame_play_func: Callable, ui_card: UICard):
	hide_modal()
	lock_hand()
	if ui_play_func:
		await ui_play_func.call($".")
	store_sibling_pasts(ui_card)
	
	HANDCONTAINER.item_rect_changed.connect(Callable(tween_hand_on_child_removed).bind(HANDCONTAINER))
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		play_card_remote.rpc(type, cardname)
	elif Globals.game_mode == Globals.modes.AI:
		ai_node.player_hand_len = HANDCONTAINER.get_child_count()-1
	ui_card.queue_free()
	played.emit(type, cardname, ingame_play_func)
	

func set_modal(type, cardname):
	if type=="" and cardname=="":
		hide_modal()
	else:
		show_modal(type, cardname)

func show_modal(type, cardname):
	Globals.cursor_state = Globals.cursor_states.HOVER
#	lock_hand()
	var pathstring = "res://Cards/Images/{0}/{1}.jpg".format([type,cardname])
	var texture = load(pathstring)
	MODALTEXTURE.texture = texture
	MODAL.visible = true


func hide_modal():
	Globals.cursor_state = Globals.cursor_states.DEFAULT
#	unlock_hand()
	MODAL.visible = false

func arm_disarm_activate_button():
	if Globals.can_activate:
		ACTIVATEBUTTON.set_texture_disabled(button_disabled_texture)
	else:
		ACTIVATEBUTTON.set_texture_disabled(button_disabled_noplayer_texture)
	ACTIVATEBUTTON.disabled = !Globals.can_activate

func _on_activate_button_pressed():
	ACTIVATEBUTTON.set_texture_normal(button_hover_texture)
	if debug:
		Globals.activate(true)
	else:
		Globals.self_activated.emit()

func other_on_activation():
	ACTIVATEBUTTON.set_texture_normal(button_other_texture)
	ACTIVATEBUTTON.set_texture_hover(button_other_hover_texture)

func on_activation():
	ACTIVATEBUTTON.visible = false
	PROGRESSBAR.visible = true
#	HAND.visible = false
	OTHERHAND.visible = false
	for card in HANDCONTAINER.get_children():
		card.activate()
	if debug:
		ACTIVETIMER.wait_time*=100
	ACTIVETIMER.start()

func on_deactivation():
	if len(deck)==0:
		if int(OTHERDECKAMOUNT.get_parsed_text())==0:
			Globals.tie.emit()
		else:
			Globals.game_end.emit(false)
	ACTIVATEBUTTON.visible = true
	PROGRESSBAR.visible = false
	HAND.visible = true
	OTHERHAND.visible = true
	ACTIVATEBUTTON.set_texture_normal(button_normal_texture)
	ACTIVATEBUTTON.set_texture_hover(button_hover_texture)
	for card in HANDCONTAINER.get_children():
		card.deactivate()
	if not ACTIVETIMER.is_stopped():
		ACTIVETIMER.stop()
	await get_tree().create_timer(1).timeout
	start_turn()

func on_cursor_change(cursor_state):
	if cursor_state in [Globals.cursor_states.SCALE, \
	Globals.cursor_states.ROTATE, \
	Globals.cursor_states.CARD]:
		lock_hand()
	else:
		unlock_hand()

func _on_active_timer_timeout():
	Globals.deactivated.emit()


func _on_table_placed(type, cardname, ui_placed_func):
	unlock_hand()


#func needplayer(ai):
#	if not ai:
#		for card in HANDCONTAINER.get_children(): 
#			if card.card_type == "Player":
#				return
#		Globals.game_end.emit(false)
#	else:
#		for card in OTHERHANDCONTAINER.get_children(): 
#			if card.card_type == "Player":
#				return
#		Globals.game_end.emit(true)

func _on_table_shown(type, cardname, ui_shown_func):
	pass


func _on_table_entered(type, cardname, ui_entered_func):
	pass # Replace with function body.


func _on_activate_button_mouse_entered():
	if not ACTIVATEBUTTON.disabled:
		Globals.cursor_state = Globals.cursor_states.HOVER


func _on_activate_button_mouse_exited():
	if not ACTIVATEBUTTON.disabled:
		Globals.cursor_state = Globals.cursor_states.DEFAULT

func end_animation(win):
	lock_hand()
	await get_tree().create_timer(0.1).timeout
	ACTIVATEBUTTON.visible = false
	await get_tree().create_timer(0.1).timeout
	HAND.visible = false
	await get_tree().create_timer(0.1).timeout
	OTHERHAND.visible = false
	await get_tree().create_timer(0.1).timeout
	visible = false

func _on_table_end_screen(win):
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		get_tree().get_root().get_node("TestLevel").queue_free()
	get_tree().change_scene_to_packed(Globals.home)
	

