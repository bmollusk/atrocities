extends AnimatableBody2D

class_name Projectile

@export var damage: float = 10
var age = 0
var dir: Vector2

var card_type 
var card_name

@export var maxAge: float = 10

@export var audio: AudioStreamPlayer2D

func init(type, cardname):
	card_type = type
	card_name = cardname
	set_collision_layer_value(4, true)
	visible = true

func _ready():
	if visible and get_collision_layer_value(4) and audio:
		audio.play()

func hitbox_entered(player):
	print("hit")
	queue_free()

func _physics_process(delta):
	if age>maxAge:
		queue_free()
	if visible and get_collision_layer_value(4):
		age += delta
