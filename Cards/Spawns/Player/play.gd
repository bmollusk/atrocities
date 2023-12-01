extends CharacterBody2D

class_name Player

var player_owner

@export var debug = false

const TEXTSPEED = 800
@export var BASESPEED = 75.0
@export var BASEHEALTH = 100
var SPEED = BASESPEED
var HEALTH = BASEHEALTH:
	set(value):
		HEALTH = value
		if multiplayer and player_owner == multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER:
			sync_health.rpc(value)
			if value <= 0 and fullyspawned:
				on_health_depleted.rpc()
		elif Globals.game_mode == Globals.modes.AI:
			if value <= 0 and fullyspawned:
				on_health_depleted()
	get:
		return HEALTH
var damage_tween: Tween
var SPRITE: Sprite2D
var OVERLAY: Node2D
var TEXTTEMPLATE: RichTextLabel
@export var spawn_scale: float = 1
@export var spawn_rotate: float = 0
@export var spawn_translate: Vector2 = Vector2()
var cards_under: Array[Node2D]
var fullyspawned = false


var sync_pos: Vector2
var sync_offset: Vector2
var sync_dir: Vector2

var card
var card_type 
var card_name
var ai_controller: AIController

@export var card_under_modulate: Color = Color.WHITE:
	set(value):
		card_under_modulate = value
		modulate_card(value)
	get:
		return card_under_modulate

signal card_destroyed
signal destroyed


func _ready():
	SPRITE = $Sprite2D
	OVERLAY = $Overlay
	TEXTTEMPLATE = $Overlay/RichTextLabel
	if not debug:
		position = Vector2(0,-sprite_y_bounds()[1])
		visible = false




func sprite_y_bounds()->Array[float]:
	return Globals.get_y_bounds(SPRITE)

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	card = card_
	card_type = s_type
	card_name = s_cardname
	name = "Player_"+name+"_"+str(id)
	spawn_scale = s_scale.x
	spawn_rotate = s_rotate
	spawn_translate = s_translate
	HEALTH = BASEHEALTH*spawn_scale
	SPEED = BASESPEED/spawn_scale
	player_owner = id
	
	

func on_spawned():
	print("fullyspawned ", player_owner, "cardname ", name, "system ", multiplayer.get_unique_id())
	fullyspawned = true
	sync_offset = global_position-sync_pos

func _process(delta):
	for text in OVERLAY.get_children():
		if not text.visible:
			continue
		text.position += -velocity.normalized()*TEXTSPEED*delta
		text.position.y -= delta*TEXTSPEED
		text.modulate.a = text.modulate.a-0.05
		if text.modulate.a <= 0:
			OVERLAY.remove_child(text)



func _physics_process(_delta):
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		if debug or player_owner==multiplayer.get_unique_id():
			var direction = Input.get_vector("Left", "Right", "Up", "Down")
			if direction:
				velocity = direction * SPEED * Globals.SPEED_MULT
			else:
		#		take_damage(1)
				velocity = Vector2.ZERO
			move_and_slide()
			
	#		print(name, " raw position ", global_position, " system ", multiplayer.get_unique_id())
			var relative_position: Vector2 = global_position - (Globals.table_bounds.position - Globals.margin)
	#		relative_position.y 
	#		print(name, " relative position ",relative_position, " system ", multiplayer.get_unique_id())
			var flipped_position = Globals.table_bounds.end + Globals.margin + relative_position.rotated(PI) 
	#		print(name, " flipped position ",flipped_position, " system ", multiplayer.get_unique_id())
			sync_info.rpc(flipped_position, direction.rotated(PI))
			if HEALTH>0:
				if not direction and Input.is_action_pressed("Destroy"):
#					if cards_under.size()>0:
					destroy_card_func.rpc()
				else:
					animation_func(direction)
					destroy_card_cancel.rpc()
		elif fullyspawned:
	#		print("synced pos", sync_pos)
			global_position = global_position.lerp(sync_pos+sync_offset, .5)
			animation_func(sync_dir)
	elif Globals.game_mode == Globals.modes.AI:
		var direction: Vector2
		if player_owner == 0:
			direction = Input.get_vector("Left", "Right", "Up", "Down")
		elif fullyspawned:
			direction = ai_controller.get_vector()
		if direction:
			velocity = direction * SPEED
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		if HEALTH>0:
			var destroy_key
			if player_owner == 0:
				destroy_key = Input.is_action_pressed("Destroy")
			else:
				destroy_key = ai_controller.destroy_key_pressed()
			if not direction and destroy_key and fullyspawned:
				destroy_card_func()
			else:
				animation_func(direction)
				destroy_card_cancel()
	
func animation_func(_direction):
	pass
	
@rpc("any_peer", "call_local")
func destroy_card_func():
	pass

@rpc("any_peer","call_local")
func destroy_card_cancel():
	pass

@rpc("any_peer", "call_remote")
func sync_info(position_, direction_):
#	print("sync info recieved from:", multiplayer.get_remote_sender_id()," to ",multiplayer.get_unique_id())
#	print("player owner: ", player_owner)
	if multiplayer.get_remote_sender_id()==player_owner:
#		print(position_)
#		print(direction_)
		sync_pos = position_
		sync_dir = direction_

@rpc("any_peer","call_remote")
func sync_health(health):
	HEALTH = health

func take_damage(damage: float):
	damage = max(damage, HEALTH-BASEHEALTH*spawn_scale)
	damage = min(damage, HEALTH)
	var text: RichTextLabel = TEXTTEMPLATE.duplicate()
	text.text = ""
	text.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	if damage<=0:
		text.push_color(Color.SEA_GREEN)
	else:
		text.push_color(Color.DARK_RED)
	text.append_text("{0}".format([HEALTH]))
	text.visible = true
	OVERLAY.add_child(text)
	text.position = TEXTTEMPLATE.position
	text.position.y = sprite_y_bounds()[1]-40
	if (player_owner == multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER)\
	or Globals.game_mode == Globals.modes.AI:
		HEALTH-=damage
	if damage_tween and damage_tween.is_valid() and damage_tween.is_running():
		damage_tween.kill()
	damage_tween = create_tween()
	var percent_health = remap(HEALTH, 0, BASEHEALTH*spawn_scale, 0, 1)
	damage_tween.tween_property(SPRITE, "modulate", \
	Color(1, percent_health, percent_health), 0.1)\
	.from(Color.CRIMSON)
	print(damage)

@rpc("any_peer", "call_local")
func on_health_depleted():
	pass

func destroy():
	destroyed.emit()

func modulate_card(color: Color):
	if len(cards_under)>0:
#		print(color)
		cards_under[-1].modulate_card_rpc(color)

func destroy_card():
	if len(cards_under)>0:
		var card_under: IngameCard = cards_under.pop_back()
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			card_under.destroy.rpc()
		elif Globals.game_mode == Globals.modes.AI:
			card_under.destroy()
		card_destroyed.emit()

func entered_card(card_: Node2D):
	cards_under.append(card_)

func exited_card(card_: Node2D):
	cards_under.erase(card_)



func _on_hitbox_body_entered(body):
	if body != self and fullyspawned:
		if "damage" in body:
			take_damage(body.damage)
		if "hitbox_entered" in body:
			body.hitbox_entered(self)
