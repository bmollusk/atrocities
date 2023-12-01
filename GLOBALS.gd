extends Node

enum modes{AI, MULTIPLAYER}

var game_mode = modes.MULTIPLAYER

const cursor = "Default"

var cards: Dictionary = {
	"Effect^Hellfire": 3, "Asset^Corpse":6, "Asset^Groves":4,"Player^Bodies":2,
 "Asset^Light":4, "Player^Enemy":2, "Effect^Burned":2, "Player^Ghoul":2, "Asset^Artillery":5,
"Asset^Balloon":5, "Asset^Disco":10, "Asset^Sparks": 8, "Asset^Wings":4, "Asset^Alien": 4,
 "Asset^Totem": 7, "Asset^Fish": 8, "Asset^Storm":3, "Player^Wastoid":2, "Effect^Halting":2,
"Asset^Flower": 4, "Asset^Brick":6, "Asset^Van":5 
}

enum tags{
	card_range, low_range, medium_range, high_range, table_range,
	damaging, healing,
	super_weak, weak, average_strength, strong, super_strong,
	projectile, spread, area, pathing,
	super_slow, slow, average_speed, fast, super_fast,
	on_contact, on_sight, on_timer, on_damage, homing,
	pick_table_card, pick_hand_card,
	delete_card, property,
	low_health, medium_health, high_health
}

var ai_tags: Dictionary = {
	"Effect^Hellfire": [tags.table_range, tags.damaging, tags.average_strength, tags.area], 
	"Asset^Groves":[tags.healing, tags.card_range, tags.super_weak, tags.area, tags.slow],
	 "Asset^Light":[tags.area, tags.super_weak, tags.low_range, tags.damaging, tags.average_speed, tags.on_contact], 
	"Effect^Burned":[tags.delete_card, tags.pick_table_card], 
	"Asset^Artillery":[tags.projectile, tags.super_fast, tags.super_weak, tags.high_range, tags.damaging, tags.on_contact],
	"Asset^Balloon":[tags.slow, tags.average_strength, tags.projectile, tags.on_timer, tags.damaging, tags.medium_range], 
	"Asset^Disco":[tags.average_speed, tags.weak, tags.projectile, tags.on_contact, tags.damaging, tags.high_range], 
	"Asset^Sparks": [tags.projectile, tags.super_weak, tags.average_speed, tags.on_contact, tags.damaging, tags.low_range, tags.spread], 
	"Asset^Wings":[tags.projectile, tags.super_weak, tags.fast, tags.on_contact, tags.damaging, tags.medium_range, tags.spread], 
	"Asset^Alien": [tags.projectile, tags.average_strength, tags.average_speed, tags.spread, tags.high_range, tags.damaging, tags.on_contact],
 	"Asset^Totem": [tags.projectile, tags.weak, tags.average_speed, tags.low_range, tags.damaging, tags.on_sight], 
	"Asset^Fish": [tags.projectile, tags.weak, tags.medium_range, tags.damaging, tags.average_speed, tags.on_contact], 
	"Asset^Storm":[tags.homing, tags.on_sight, tags.medium_range, tags.damaging, tags.average_strength, tags.area, tags.projectile, tags.slow], 
	"Effect^Halting":[tags.table_range, tags.property, tags.super_slow],
	"Asset^Flower": [tags.low_range, tags.area, tags.property, tags.super_slow],
	"Asset^Brick":[tags.high_range, tags.pathing, tags.slow], 
	"Asset^Van":[tags.high_range, tags.pathing, tags.average_speed, tags.damaging, tags.on_damage, tags.on_timer, tags.area, tags.medium_health],
	"Player^Bodies": [tags.average_speed, tags.high_health],
	"Player^Enemy": [tags.fast, tags.medium_health, tags.damaging, tags.area, tags.on_timer],
	"Player^Ghoul": [tags.average_speed, tags.low_health],
	"Player^Wastoid": [tags.fast, tags.medium_health]
}

enum cursor_states{NONE, DEFAULT, HOVER, CARD, SCALE, ROTATE}
var cursor_state = cursor_states.DEFAULT:
	set(value):
		cursor_state = value
		cursorchanged.emit(cursor_state)
	get:
		return cursor_state
var table_bounds: Rect2
var margin: Vector2

signal cursorchanged(state)
signal sendcursorpos(pos: Vector2)

signal activated
var active = false
signal self_activated
var self_active = false
signal other_activated
var other_active = false

var P1
var opponent

signal deactivated
signal arm_state_change
var can_activate = false:
	set(value):
		can_activate = value
		arm_state_change.emit()
	get:
		return can_activate

signal game_end(win)
signal tie(level)
var game_ended = false

const SCALE_SNAP = 0.25
const ROTATE_SNAP = PI/8
const MIN_SCALE = 75
const MAX_SCALE = 150

var SPEED_MULT = 2
var HANDSIZE = 7

var home = preload("res://GUI/main_menu.tscn")
var mult_menu = preload("res://GUI/mulltiplayer_menu.tscn")
var sing_menu = preload("res://Level/malice_level.tscn")

func get_y_bounds(SPRITE: Sprite2D)->Array[float]:
	var scaled_size = SPRITE.texture.get_size()/SPRITE.vframes*SPRITE.scale
	var yupper = scaled_size.y/2+SPRITE.position.y*-1
	var ylower = scaled_size.y/2+SPRITE.position.y
	return [-ylower, -yupper]

func card_str_to_arr(str):
	return Array(str.split("^", false, 1))

func card_arr_to_str(arr):
	return arr[0]+"^"+arr[1]

func get_tags(arr):
	var str = card_arr_to_str(arr)
	if str in ai_tags:
		return ai_tags[str]
	else:
		return []

func rotation_to_frame_coords(rotation, frameoffset):
	if rotation<0:
		rotation = 2*PI+rotation
	return (snapped(remap(rotation, 0, 2*PI, 0, 16),1)+frameoffset)%16

# Called when the node enters the scene tree for the first time.
func _ready():
	
	self_activated.connect(activate_remote)
	self_activated.connect(activate)
	other_activated.connect(activate)
	
	deactivated.connect(deactivate_remote)
	
	game_end.connect(game_end_remote)

func activate_remote():
	self_active = true
	if game_mode==modes.MULTIPLAYER:
		activate_recieve.rpc()
	
@rpc("any_peer")
func activate_recieve():
	print(multiplayer.get_remote_sender_id(), " has activated")
	other_active = true
	other_activated.emit()

func activate(debug=false):
	if debug or (other_active and self_active):
		activated.emit()
		active= true

func deactivate_remote():
	if self_active and other_active:
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			deactivate_recieve.rpc()
		active = false
		self_active = false
		other_active = false
	
@rpc("any_peer")
func deactivate_recieve():
	if self_active and other_active:
		deactivated.emit()
		active = false

func game_end_remote(win):
	if not game_ended:
		if win:
			print("you won!")
		else: 
			print("you lost!")
		game_ended = true
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			game_end_recieve.rpc(not win)

@rpc("any_peer")
func game_end_recieve(win):
	if not game_ended:
		game_ended
		game_end.emit(win)

func if_norot(rot, card_owner):
	if multiplayer.get_unique_id()!=card_owner:
		return rot-PI
	return rot

func fix_neg_rot(rot):
	if rot<0:
		return 2*PI+rot
	return rot
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func snap_pos(pos):
	var position_snapped = snapped(pos, 25*Vector2.ONE)
	position_snapped = position_snapped.clamp(Globals.table_bounds.position,\
		 Globals.table_bounds.end)
	return position_snapped

func snap_scale(scale_):
	var scale_float = clamp(scale_, MIN_SCALE, MAX_SCALE)
	scale_float = remap(scale_float, MIN_SCALE, MAX_SCALE, 1, 2)
	return snapped(scale_float,SCALE_SNAP)
	
func snap_rot(rot):
	return snapped(rot, ROTATE_SNAP)

func rand_vect():
	return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func flip_pos(pos):
	var relative_position: Vector2 = pos - Globals.table_bounds.position 
	var flipped_position = Globals.table_bounds.end + relative_position.rotated(PI)
	return flipped_position
