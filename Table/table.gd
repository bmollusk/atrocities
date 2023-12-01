extends Node2D

class_name Table

@export var use_debug_deck = false
@export var use_decals = false

@export var debug_deck = [["Asset", "Balloon"], ["Asset", "Van"], ["Asset", "Sparks"], ["Effect", "Hellfire"], ["Player", "Wastoid"],\
["Asset", "Wings"], ["Asset", "Storm"], ["Asset", "Light"], ["Player", "Ghoul"], ["Effect", "Halting"]]

@export var texture: Texture2D
@export var sidetexture: Texture2D
@export var summoning_color: Color
@export var light_color: Color
@export var shadow_color: Color
@export var decals: Array[Texture2D]

signal placed(type, cardname, ui_placed_func:Callable)
signal shown(type, cardname, ui_shown_func:Callable)
signal entered(type, cardname, ui_entered_func:Callable)
signal needplayer(ai)

signal load_deck(deck)

signal end_screen(win)

var on_every_spawn: Array[Callable]



var TABLE: Sprite2D
var DECKS: Node2D
var SUMMONCIRCLE: Node2D
var TABLEBORDER: Sprite2D
var CAMERA: Node2D
var PLAYERGROUP: Node2D
var SPAWNS: Node2D
var OVERLAYS: Node2D

const SCALE_FACTOR = 0.75
const ZOOM_FACTOR = 2

var pickedplayer: Node2D
 

@export var ai_node: GameAI
# Called when the node enters the scene tree for the first time.
func _ready():
	TABLE = $Table
	TABLE.texture = texture
	DECKS = $Decks
	SUMMONCIRCLE = $SummoningCircle
	SUMMONCIRCLE.modulate = summoning_color
	TABLEBORDER = $TableBorder
	TABLEBORDER.texture = sidetexture
	TABLEBORDER.scale.y = 0
	CAMERA = $Camera
	CAMERA.focus = TABLE
	PLAYERGROUP = $Player
	SPAWNS = $Spawns
	OVERLAYS = $Overlays
	set_table_bounds()
	var leftx = Globals.table_bounds.end.x+Globals.margin.x
	var rightx = Globals.table_bounds.position.x-Globals.margin.x
	var topy = Globals.table_bounds.position.y-Globals.margin.y
	var bottomy = Globals.table_bounds.end.y+Globals.margin.y
	add_collision_bound(40, \
	Vector2(leftx, topy),\
	Vector2(leftx, bottomy))
	add_collision_bound(40, \
	Vector2(rightx, bottomy),\
	Vector2(rightx, topy))
	add_collision_bound(40, \
	Vector2(leftx, topy),\
	Vector2(rightx, topy))
	add_collision_bound(40, \
	Vector2(rightx, bottomy),\
	Vector2(leftx, bottomy))
	
	Globals.activated.connect(on_activation)
	Globals.deactivated.connect(on_deactivation)
	Globals.tie.connect(tie_check)
	Globals.game_end.connect(end_animation)
	
	
	if ai_node:
		Globals.game_mode = Globals.modes.AI
		ai_node.place_card_func = place_card_remote
		
	var multiplayer_condition = Globals.game_mode == Globals.modes.MULTIPLAYER and (use_debug_deck or Globals.P1 == multiplayer.get_unique_id())
	
	if multiplayer_condition or Globals.game_mode == Globals.modes.AI:
		$GameStartTimer.start()
		
	

@rpc("any_peer","call_local")
func game_start(decks, colors):
	var ind = 0
	for marker in DECKS.get_children():
		var deck: Deck = preload("res://Decks/deck.tscn").instantiate()
		var i = ind
		if Globals.P1 == multiplayer.get_unique_id():
			i = 2-i
		deck.init(decks[i], colors[i])
		deck.picked.connect(deck_pick.bind(i))
		deck.name = "Deck"+str(i)
		deck.position = marker.global_position
		DECKS.add_child(deck)
		ind+=1
		await get_tree().create_timer(0.5).timeout


func deck_pick(deck_ind):
	var deck: Deck = DECKS.find_child("Deck"+str(deck_ind), false, false)
	deck.pick()
	deck.gone = true
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		deck_pick_remote.rpc(deck_ind)
	elif Globals.game_mode == Globals.modes.AI:
		ai_node.pick_deck(deck_ind, deck_pick_remote)
	update_decks_status()
 
@rpc("any_peer")
func deck_pick_remote(deck_ind):
	var deck: Deck = DECKS.find_child("Deck"+str(deck_ind), false, false)
	deck.pick()
	deck.gone = true
	update_decks_status()

func update_decks_status():
	for otherdeck in DECKS.find_children("Deck?", "Node2D", false, false):
		if is_instance_valid(otherdeck):
			if otherdeck.p2 and not otherdeck.gone:
				await get_tree().create_timer(1).timeout
				otherdeck.pick()
				load_deck.emit(otherdeck.deck)
				Globals.cursor_state = Globals.cursor_states.DEFAULT
			else:
				otherdeck.p2 = true

func _on_game_start_timer_timeout():
	if use_debug_deck:
		load_deck.emit(debug_deck)
	else:
		var decks = []
		var colors = []
		for i in range(3):
			var deck = Deck.gen_deck()
			decks.append(deck)
			var color = Color.from_hsv(randf(),0.6,1)
			colors.append(color)
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			game_start.rpc(decks, colors)
		elif Globals.game_mode == Globals.modes.AI:
			game_start(decks, colors)
			
			
	
func add_collision_bound(boundsize, start:Vector2, end:Vector2, collision_layer=4, collision_mask=2):
	var bound = RectangleShape2D.new()
	bound.size = Vector2(boundsize, start.distance_to(end))
	var collision = CollisionShape2D.new()
	collision.set_shape(bound)
	collision.position = Vector2(boundsize/2, 0)
	var body = StaticBody2D.new()
	body.add_child(collision)
	body.position = (end-start)/2+start
	body.rotation = start.direction_to(end).angle_to(Vector2.DOWN)
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	add_child(body)
	


func init_card(type, cardname, playerid):
	var ingame_card: Node2D
	var specialcardpath = "res://Cards/Ingame/{0}/{1}.tscn".format([type,cardname.to_snake_case()])
	if ResourceLoader.exists(specialcardpath):
		ingame_card = load(specialcardpath).instantiate()
	else:
		ingame_card = preload("res://Cards/Ingame/ingame_card.tscn").instantiate()
	if "init_card" in ingame_card:
		ingame_card.init_card(type,cardname, playerid)
	return ingame_card

func _on_ui_played(type: String, cardname: String, ingame_play_func: Callable):
	if ingame_play_func:
		ingame_play_func.call($".") 
	var ingame_card
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		ingame_card = init_card(type, cardname, multiplayer.get_unique_id())
	elif Globals.game_mode == Globals.modes.AI:
		ingame_card = init_card(type, cardname, 0)
	if "placed" in ingame_card:
		ingame_card.placed.connect(place_card)
	if "shown" in ingame_card:
		ingame_card.shown.connect(card_shown)
	if "opened" in ingame_card:
		ingame_card.opened.connect(Callable(eye_opened).bind(ingame_card))
	if "entered" in ingame_card:
		ingame_card.entered.connect(card_entered)
	if "exited" in ingame_card:
		ingame_card.exited.connect(card_exited)
	if "spawned" in ingame_card:
		ingame_card.spawned.connect(spawned)
	if "spawn_destroyed" in ingame_card:
		ingame_card.spawn_destroyed.connect(Callable(spawn_destroyed).bind(ingame_card))
	if "destroyed" in ingame_card:
		ingame_card.destroyed.connect(Callable(destroyed).bind(ingame_card))
	
	if "on_every_spawn_func" in ingame_card:
		on_every_spawn.append(ingame_card.on_every_spawn_func)
		
	if type == "Player":
		Globals.can_activate = true
	var nodepath = type
	get_node(nodepath).add_child(ingame_card)
	Globals.cursor_state = Globals.cursor_states.CARD

func set_table_bounds():
	var sprite_scaled_size = TABLE.texture.get_size()*TABLE.global_scale
	var sprite_start_position = sprite_scaled_size*-0.5+TABLE.global_position
	Globals.margin = Vector2.ONE*50
	var rect = Rect2(sprite_start_position+Globals.margin, sprite_scaled_size-2*Globals.margin)	
	Globals.table_bounds = rect

@rpc("any_peer")
func place_card_remote(type: String, cardname: String,\
	position_, scale_, rotation_, playerid):
	
	print(playerid)
	print(type, " ", cardname, " position ", position_, " scale ", scale_, " rotation ",  rotation_)
	var ingame_card = init_card(type, cardname, playerid)
	if "default_ingame_placed_func" in ingame_card:
		ingame_card.default_ingame_placed_func.call($".")
	var ui_placed_func
	if "default_ui_placed_func" in ingame_card:
		ui_placed_func = ingame_card.default_ui_placed_func
	else:
		ui_placed_func = null
	placed.emit(type, cardname, ui_placed_func)
#	ingame_card.name = card_unique_name
	var relative_position: Vector2 = position_ - Globals.table_bounds.position 
	var flipped_position = Globals.table_bounds.end + relative_position.rotated(PI)
	var flipped_rotation = rotation_+PI
	ingame_card.set_placed(flipped_position, scale_, flipped_rotation)
	if "shown" in ingame_card:
		ingame_card.shown.connect(card_shown)
	if "opened" in ingame_card:
		ingame_card.opened.connect(Callable(eye_opened).bind(ingame_card))
	if "entered" in ingame_card:
		ingame_card.entered.connect(card_entered)
	if "exited" in ingame_card:
		ingame_card.exited.connect(card_exited)
	if "spawned" in ingame_card:
		ingame_card.spawned.connect(spawned)
	if "spawn_destroyed" in ingame_card:
		ingame_card.spawn_destroyed.connect(Callable(spawn_destroyed).bind(ingame_card))
	if "destroyed" in ingame_card:
		ingame_card.destroyed.connect(Callable(destroyed).bind(ingame_card))
		
	if "on_every_spawn_func" in ingame_card:
		on_every_spawn.append(ingame_card.on_every_spawn_func)
		
	var nodepath = type
	get_node(nodepath).add_child(ingame_card)

func place_card(type: String, cardname: String, ui_placed_func:Callable, ingame_placed_func:Callable,\
	position_, scale_, rotation_):
	if ingame_placed_func:
		ingame_placed_func.call($".")
	placed.emit(type, cardname, ui_placed_func)
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		place_card_remote.rpc(type, cardname,\
		position_, scale_, rotation_, multiplayer.get_unique_id())
	elif Globals.game_mode == Globals.modes.AI:
		ai_node.player_place_card(type, cardname, position_, scale_, rotation_)
	

func on_activation():
	if Globals.can_activate:
		activate()
#	else:
#		no_player()



func default_player_select(ai = false):
	var yourplayers = []
	for player in PLAYERGROUP.get_children():
		if not is_instance_valid(player):
			continue
		var multiplayer_condition = player.card_owner == multiplayer.get_unique_id()
		multiplayer_condition = multiplayer_condition and Globals.game_mode == Globals.modes.MULTIPLAYER
		
		var ai_condition = (not ai and player.card_owner == 0) or (ai and player.card_owner == 1)
		ai_condition = ai_condition and Globals.game_mode == Globals.modes.AI
		
		if multiplayer_condition or ai_condition:
			yourplayers.append(player)
	if yourplayers.size()>0:
		return yourplayers.pick_random()
	else:
		return null

func pick_player(ai = false, player_select_func=default_player_select):
	if not ai:
		if !pickedplayer:
			pickedplayer = player_select_func.call()
		return pickedplayer
	else:
		if !ai_node.pickedplayer:
			ai_node.pickedplayer = player_select_func.call(ai)
		return ai_node.pickedplayer

func tweensetup(ease_: Tween.EaseType = Tween.EASE_IN_OUT, trans_: Tween.TransitionType = Tween.TRANS_LINEAR)-> Tween:
	var tween = create_tween()
	tween.set_ease(ease_)
	tween.set_trans(trans_)
	tween.set_parallel()
	return tween

func zoomin(focus: Node2D, tween: Tween):
	CAMERA.tween = tween
	CAMERA.mouse_influence = 0
	CAMERA.focus = focus
	CAMERA.zoom = Vector2.ONE*ZOOM_FACTOR
	

func zoomout(tween: Tween):
	CAMERA.tween = tween
	CAMERA.zoom = Vector2.ONE
	CAMERA.focus = TABLE
	CAMERA.mouse_influence = 1

func activate_card(card: Node2D):
	card.activate()

func deactivate_card(card: Node2D):
	card.deactivate()

func generate_decals():
	if use_decals:
		for i in range(50):
			var decal = decals.pick_random()
			var sprite = Sprite2D.new()
			sprite.texture = decal
			sprite.offset = Vector2(0,-decal.get_height()/2)
			SPAWNS.add_child(sprite)
			sprite.scale = Vector2.ONE*0.2
			var xpos = randf_range(Globals.table_bounds.position.x-Globals.margin.x, Globals.table_bounds.end.x+Globals.margin.x)
			var ypos = randf_range(Globals.table_bounds.position.y-Globals.margin.y, Globals.table_bounds.end.y+Globals.margin.y)
			sprite.position = Vector2(xpos, ypos)
			await get_tree().create_timer(.2).timeout

func activate():
	$"../PlaceSong".stop()
	$"../ActiveSong".play()
	var zoomtween = tweensetup(Tween.EASE_IN_OUT, Tween.TRANS_EXPO)
	zoomtween.tween_property(self, "scale", Vector2(1,SCALE_FACTOR), 2)
	zoomtween.tween_property(TABLE, "self_modulate", light_color, 2)
	zoomtween.tween_property(TABLEBORDER, "scale", Vector2(TABLE.scale.x,TABLE.scale.x/SCALE_FACTOR) , 2)
	zoomtween.tween_property(TABLEBORDER, "self_modulate", shadow_color , 2).from(light_color)
	var i = 0
	for circle in SUMMONCIRCLE.get_children():
		zoomtween.tween_property(circle, "rotation", PI*i, 2)
		zoomtween.tween_property(circle, "position", circle.position-Vector2(0, i*200), 2)
		if i!=0:
			zoomtween.tween_property(circle, "self_modulate", Color(circle.self_modulate, 0), 2)
		i+=1
	
	
	var player_card:IngameCard = pick_player()
	player_card.open_eye()
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		player_card.open_eye.rpc()
	if Globals.game_mode == Globals.modes.AI:
		var ai_player_card:IngameCard = pick_player(true)
		ai_player_card.open_eye()
	zoomin(player_card, zoomtween)
	zoomtween.set_parallel(false)
	zoomtween.tween_callback(func(): call_deferred("activate_cards"))
	zoomtween.tween_callback(func(): call_deferred("spawn_player"))
	if Globals.game_mode == Globals.modes.AI:
		zoomtween.parallel().tween_callback(func(): call_deferred("spawn_player", true))
	zoomtween.tween_callback(func(): OVERLAYS.global_scale = Vector2.ONE)
	zoomtween.tween_callback(generate_decals)
#	Globals.cursor_state = Globals.cursor_states.NONE
	Globals.sendcursorpos.emit(Vector2())

func activate_cards():
	for card_group in get_children():
		if card_group.name not in ["Asset", "Effect", "Player"]:
			continue
		for card in card_group.get_children():
			activate_card(card)
#			await get_tree().create_timer(0.1).timeout

func spawn_player(ai = false):
	var spawntween
	if not ai:
		spawntween = tweensetup()
	var player_spawn: Player
	if Globals.game_mode == Globals.modes.AI and ai:
#		for spawn in SPAWNS.get_children():
#			if spawn is Player and spawn.player_owner == 1 and is_instance_valid(spawn):
#				print("ai player already spawned")
#				return
		print("ai player respawned")
		if not ai_node.pickedplayer:
			Globals.deactivated.emit()
			return 
		player_spawn = ai_node.pickedplayer.show_card()
	else:
#		for spawn in SPAWNS.get_children():
#			if spawn is Player and (spawn.player_owner == 0 or spawn.player_owner == multiplayer.get_unique_id()) and is_instance_valid(spawn):
#				print("your player already spawned")
#				return
		print("your player respawned possible")
		if not pickedplayer:
			Globals.deactivated.emit()
			return
		player_spawn = pickedplayer.show_card()
		print("uh huh it did")
		
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		print("multiplayer spawn signal sent")
		pickedplayer.show_card.rpc()
		
	if Globals.game_mode == Globals.modes.AI and ai:
		print("ai controller reparented")
		ai_node.ai_controller.reparent(player_spawn, false)
		player_spawn.ai_controller = ai_node.ai_controller
		ai_node.ai_controller.init_info(player_spawn)
		
	if not ai:
		spawntween.bind_node(player_spawn)
		#spawntween.tween_property(self, "mouse_influence", 1.5, 2)
		CAMERA.tween = spawntween
		CAMERA.focus = player_spawn

func card_shown(type: String, cardname: String, ui_shown_func:Callable, ingame_shown_func:Callable):
	if ingame_shown_func:
		ingame_shown_func.call($".")
	shown.emit(type, cardname, ui_shown_func)

func eye_opened(type: String, _cardname: String, _ui_opened_func:Callable, ingame_opened_func:Callable, card: Node2D):
	print("opened", multiplayer.get_unique_id())
	if ingame_opened_func:
		ingame_opened_func.call($".")
	if type=="Player":
		var eyeopen = Sprite2D.new()
		eyeopen.texture = load("res://Overlays/OpenEye.png")
		eyeopen.position = card.global_position
		var eyetween = tweensetup(Tween.EASE_OUT, Tween.TRANS_EXPO)
		eyetween.tween_property(eyeopen, "scale", Vector2.ONE*2, 2).from(Vector2.ZERO)
		eyetween.tween_property(eyeopen, "modulate", Color(eyeopen.modulate, 0), 2)
		eyetween.set_parallel(false)
		eyetween.tween_callback(eyeopen.queue_free)
		OVERLAYS.add_child(eyeopen)
	
func card_entered(type: String, cardname: String, ui_entered_func:Callable, ingame_entered_func:Callable):
	if ingame_entered_func:
		ingame_entered_func.call($".")
	shown.emit(type, cardname, ui_entered_func)


func card_exited(type: String, cardname: String, ui_exited_func:Callable, ingame_exited_func:Callable):
	if ingame_exited_func:
		ingame_exited_func.call($".")
	shown.emit(type, cardname, ui_exited_func)

func spawned(_type: String, _cardname: String, _ui_spawned_func:Callable, ingame_spawned_func:Callable, spawn: Node2D):
	if ingame_spawned_func:
		ingame_spawned_func.call($".")
#	var id = multiplayer.get_unique_id()
#	if multiplayer.get_remote_sender_id()!=multiplayer.get_unique_id():
#		print("spawned remotely")
	spawn.reparent(SPAWNS)
	

func spawn_destroyed(type: String, _cardname: String, _ui_spawn_destroyed_func:Callable, ingame_spawn_destroyed_func:Callable, spawn: Node2D, card: IngameCard):
	var multiplayer_condition = Globals.game_mode==Globals.modes.MULTIPLAYER and card.card_owner == multiplayer.get_unique_id()
	var ai_condition = Globals.game_mode==Globals.modes.AI and card.card_owner == 0
	if type=="Player":
		if multiplayer_condition or ai_condition:
			pickedplayer = null
		elif Globals.game_mode == Globals.modes.AI and card.card_owner==1:
			ai_node.pickedplayer == null 
	if ingame_spawn_destroyed_func:
		ingame_spawn_destroyed_func.call($".")
	if type=="Player":
		print("player was killed")
		if multiplayer_condition or ai_condition:
			print("player being respawned...")
			CAMERA.tween = tweensetup(Tween.EASE_IN, Tween.TRANS_BOUNCE)
			CAMERA.focus = card
			
			pick_player()
	#		player_card.open_eye()
	#		spawn_player()
			call_deferred("spawn_player")
		elif Globals.game_mode == Globals.modes.AI and card.card_owner==1:
			print("controller was reparented")
			spawn.ai_controller.reparent(ai_node, false)
			ai_node.ai_controller = spawn.ai_controller
			pick_player(true)
			call_deferred("spawn_player", true)
	spawn.queue_free()

func player_no_spawn(card_owner, spawn = null):
	var multiplayer_condition = Globals.game_mode==Globals.modes.MULTIPLAYER and card_owner == multiplayer.get_unique_id()
	var ai_condition_human = Globals.game_mode==Globals.modes.AI and card_owner == 0
	var ai_condition_ai = Globals.game_mode == Globals.modes.AI and card_owner==1
	if multiplayer_condition or ai_condition_human:
		pickedplayer = null
		pick_player()
		print("player being respawned...")
		call_deferred("spawn_player")
	elif ai_condition_ai:
		ai_node.pickedplayer = null
		print("controller was reparented in the player no spawn func")
		if spawn:
			spawn.ai_controller.reparent(ai_node, false)
			ai_node.ai_controller = spawn.ai_controller
		else:
			print("spawn ai controller was not supplied so there was  sequence error")
		pick_player(true)
		call_deferred("spawn_player", true)
	

func destroyed(type: String, cardname: String, _ui_destroyed_func:Callable, ingame_destroyed_func:Callable, card: IngameCard):
	if ingame_destroyed_func:
		ingame_destroyed_func.call($".")
	if Globals.game_mode == Globals.modes.AI and card.card_owner == 0:
		ai_node.player_remove_card(type, cardname, card.position, card.scale, card.rotation)
	if type == "Player":
		if card.card_visible:
			var found = false
			for spawn in SPAWNS.get_children():
				if spawn is Player and spawn.card == card and is_instance_valid(spawn):
					print("player card was destroyed but its destroy signal has been reconnected to player_no_spawn")
					spawn.destroyed.connect(Callable(player_no_spawn).bind(card.card_owner, spawn))
					found = true
			if not found:
				print("player may have already been destroyed, as its not found")
				player_no_spawn(card.card_owner, null)
		var ai_condition = Globals.game_mode == Globals.modes.AI and card.card_owner == 1
		if ai_condition:
			ai_node.can_activate = can_activate(ai_condition)
		else:
			Globals.can_activate = can_activate()
#		no_player()
	card.queue_free()


func can_activate(ai=false):
	for card in PLAYERGROUP.get_children():
		var multiplayer_condition = card.card_owner == multiplayer.get_unique_id()
		multiplayer_condition = multiplayer_condition and Globals.game_mode == Globals.modes.MULTIPLAYER
		
		var ai_condition = (not ai and card.card_owner == 0) or (ai and card.card_owner == 1)
		ai_condition = ai_condition and Globals.game_mode == Globals.modes.AI
		if multiplayer_condition or ai_condition:
			return true
	return false

#func no_player():
#	if not Globals.self_active and not Globals.other_active:
#		if not can_activate():
#			needplayer.emit(false)
#		if Globals.game_mode==Globals.modes.AI and not can_activate(true):
#			needplayer.emit(true)

func deactivate():
	$"../PlaceSong".play()
	$"../ActiveSong".stop()
	pickedplayer = null
	var zoomtween = tweensetup(Tween.EASE_IN_OUT, Tween.TRANS_EXPO)
	zoomtween.tween_property(self, "scale", Vector2.ONE, 2)
	zoomtween.tween_property(TABLE, "self_modulate", Color.WHITE, 2)
	zoomtween.tween_property(TABLEBORDER, "scale", Vector2(TABLE.scale.x, 0) , 2)
	zoomtween.tween_property(TABLEBORDER, "self_modulate", light_color, 2)
	var i = 0
	for circle in SUMMONCIRCLE.get_children():
		zoomtween.tween_property(circle, "rotation", 0, 2)
		zoomtween.tween_property(circle, "position", circle.position+Vector2(0, i*200), 2)
		if i!=0:
			zoomtween.tween_property(circle, "self_modulate", Color(circle.self_modulate, 1), 2)
		i+=1
	for card_group in get_children():
		if card_group.name not in ["Asset", "Effect", "Player"]:
			continue
		for card in card_group.get_children():
			deactivate_card(card)
	for spawn in SPAWNS.get_children():
		if "player_owner" in spawn:
			if spawn.player_owner == 1:
				spawn.ai_controller.reparent(ai_node, false)
				ai_node.ai_controller = spawn.ai_controller
		spawn.queue_free()
	zoomout(zoomtween)
#	Globals.cursor_state = Globals.cursor_states.DEFAULT
	Globals.can_activate = can_activate()
	if Globals.game_mode == Globals.modes.AI:
		ai_node.can_activate = can_activate(true)

func on_deactivation():
	deactivate()

func _on_spawns_child_entered_tree(node):
	var updated_functions_list: Array[Callable]
	for function in on_every_spawn:
		if not function.is_null() and function.is_valid():
			function.call(node)
			updated_functions_list.append(function)
	on_every_spawn = updated_functions_list

func tie_check():
	if Globals.game_mode == Globals.modes.AI:
		var yourtotal = 0
		var aitotal = 0
		for card_group in get_children():
			if card_group.name not in ["Asset", "Effect", "Player"]:
				continue
			for card in card_group.get_children():
				if card.card_owner == 0:
					yourtotal+=1*card.scale.x
					if card.card_type == "Effect":
						yourtotal+=1
				else:
					aitotal+=1*card.scale.x
					if card.card_type == "Effect":
						aitotal+=1
		if yourtotal>aitotal:
			Globals.game_end.emit(true)
		else:
			Globals.game_end.emit(false)
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		var yourtotal = 0
		var othertotal = 0
		for card_group in get_children():
			if card_group.name not in ["Asset", "Effect", "Player"]:
				continue
			for card in card_group.get_children():
				if card.card_owner == multiplayer.get_unique_id():
					yourtotal+=1*card.scale.x
					if card.card_type == "Effect":
						yourtotal+=1
					if card.card_type == "Player":
						yourtotal+=2
				else:
					othertotal+=1*card.scale.x
					if card.card_type == "Effect":
						othertotal+=1
					if card.card_type == "Player":
						othertotal+=2
		if yourtotal<=othertotal:
			Globals.game_end.emit(false)

func end_animation(win):
	await get_tree().create_timer(5).timeout
	var tween = create_tween()
	tween.tween_property(SUMMONCIRCLE, "modulate", Color.MEDIUM_VIOLET_RED,4)
	if win:
		$GPUParticles2D/AnimationPlayer.play("win")
	else:
		$GPUParticles2D/AnimationPlayer.play("lose")
	


func _on_animation_player_animation_finished(anim_name):
	end_screen.emit(str(anim_name))


