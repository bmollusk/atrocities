extends AnimatableBody2D

class_name Asset

@export var debug = false

var asset_owner

var SPRITE: Sprite2D


@export var spawn_scale: float = 1
@export var spawn_rotate: float = 0
@export var spawn_translate: Vector2 = Vector2()

var card
var card_type 
var card_name

var fullyspawned = false

signal destroyed

func _ready():
	SPRITE = $Sprite2D
	if not debug and not fullyspawned:
		position = Vector2(0,-sprite_y_bounds()[1])
		visible=false


func on_spawned():
	print("fullyspawned ", asset_owner)
	fullyspawned = true

func sprite_y_bounds()->Array[float]:
	return Globals.get_y_bounds(SPRITE)

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	card = card_
	card_type = s_type
	card_name = s_cardname
	if s_scale is Vector2:
		spawn_scale = s_scale.x
	else:
		spawn_scale = s_scale
	spawn_rotate = s_rotate 
	spawn_translate = s_translate
	asset_owner = id

func destroy():
	destroyed.emit()

func entered_card(card: Node2D):
	pass

func exited_card(card: Node2D):
	pass
