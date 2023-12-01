extends Node2D


var SPRITE: Sprite2D
var OTHERSPRITE: Sprite2D 
var other_pos= Vector2(500, 20)

var win = true

const textures = {
	Globals.cursor_states.NONE: "",
	Globals.cursor_states.DEFAULT: "Default.png",
	Globals.cursor_states.HOVER: "Hover.png",
	Globals.cursor_states.CARD: "Card.png",
	Globals.cursor_states.SCALE: "Scale.png",
	Globals.cursor_states.ROTATE: "Rotate.png",
	}


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	SPRITE = $CanvasLayer/Sprite2D
	OTHERSPRITE = $CanvasLayer/Sprite2D2
	change_cursor_sprite(Globals.cursor_state)
#	send_info(Vector2(get_viewport_rect().get_center().x, 0))
	Globals.cursorchanged.connect(change_cursor_sprite)
#	Globals.sendcursorpos.connect(send_info)
	
	Globals.game_end.connect(end_anim)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#func send_info(pos):
#	change_cursor_remote.rpc(Globals.cursor, Globals.cursor_state, pos)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Globals.game_ended:
		if win:
			SPRITE.position = get_viewport().get_mouse_position()
#		else:
#			OTHERSPRITE.position = lerp(OTHERSPRITE.position, other_pos, 0.5)
	else:
		SPRITE.position = get_viewport().get_mouse_position()
#		OTHERSPRITE.position = lerp(OTHERSPRITE.position, other_pos, 0.5)

func change_cursor_sprite(state):
	var current_image = textures[state]
	if current_image=="":
		SPRITE.texture = null
	else:
		var cursor_name = Globals.cursor
		var pathstring = "res://Cursors/{0}/{1}".format([cursor_name, current_image])
		SPRITE.texture = load(pathstring)

#@rpc("any_peer")
#func change_cursor_remote(cursor_name, state, pos):
#	var current_image = textures[state]
#	if current_image=="":
#		OTHERSPRITE.texture = null
#	else:
#		var pathstring = "res://Cursors/{0}/{1}".format([cursor_name, current_image])
#		OTHERSPRITE.texture = load(pathstring)
#	other_pos = pos

func end_anim(win_):
	win = win_
	change_cursor_sprite(Globals.cursor_states.DEFAULT)
#	change_cursor_remote.rpc(Globals.cursor, Globals.cursor_states.DEFAULT, Vector2(get_viewport_rect().get_center().x, 0))
	var tween = create_tween()
	if win:
		tween.tween_property(OTHERSPRITE, "position", get_viewport_rect().get_center(), 10)
	else:
		tween.tween_property(SPRITE, "position", get_viewport_rect().get_center(), 10)
	
