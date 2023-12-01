extends Control

class_name UICard

var card_owner
var card_type: String
var card_name: String
signal played(type: String,cardname: String, ui_play_func: Callable, ingame_play_func: Callable)
signal modal(type: String,cardname: String)

var HOVERTIMER: Timer
var CARDTEXTUREBUTTON: TextureButton
var OVERLAY: TextureRect

var playable = true:
	get: 
		return playable
	set(value):
		enable_overlay(value)
		playable=value


func init_card(type, cardname, c_owner, other = false):
	CARDTEXTUREBUTTON = $MarginContainer/TextureButton
	HOVERTIMER = $HoverTimer
	OVERLAY = $MarginContainer/TextureButton/TextureRect
	
	var pathstring = "res://Cards/Images/{0}/{1}.jpg".format([type,cardname])
	var texture = load(pathstring)
	CARDTEXTUREBUTTON.set_texture_normal(texture)
	
	card_type = type
	card_name = cardname
	card_owner = c_owner
	
	if other:
		var backtexture
		if Globals.game_mode == Globals.modes.MULTIPLAYER:
			if Globals.P1 == card_owner:
				backtexture = load("res://Cards/Images/Back.jpg")
			else:
				backtexture = load("res://Cards/Images/Back2.jpg")
		elif Globals.game_mode == Globals.modes.AI:
			backtexture = load("res://Cards/Images/Back.jpg")
		CARDTEXTUREBUTTON.set_texture_disabled(backtexture)
		CARDTEXTUREBUTTON.disabled = true
	else:
		if card_type == "Effect":
			playable = Globals.active 
		elif card_type == "Player":
			playable = not Globals.active
			
		CARDTEXTUREBUTTON.disabled = not playable

func enable_overlay(enabled):
	if OVERLAY:
		OVERLAY.visible = not enabled

func play(type=card_type, \
		cardname=card_name, \
		ui_play_func=default_ui_play_func, \
		ingame_play_func=default_ingame_play_func):
	played.emit(type, cardname, ui_play_func, ingame_play_func)

func lock():
	HOVERTIMER.stop()
	if playable:
		CARDTEXTUREBUTTON.disabled = true

func unlock():
	if playable:
		CARDTEXTUREBUTTON.disabled = false

func activate():
	if card_type=="Effect":
		playable=true
		CARDTEXTUREBUTTON.disabled = false
	elif card_type=="Player":
		playable=false
		CARDTEXTUREBUTTON.disabled = true

func deactivate():
	if card_type=="Effect":
		playable=false
		CARDTEXTUREBUTTON.disabled = true
	elif card_type=="Player":
		playable=true
		CARDTEXTUREBUTTON.disabled = false
	
func default_ui_play_func(_ui: Control):
	pass

func default_ingame_play_func(_ingame: Node2D):
	pass

func _on_texture_button_pressed():
	play()


func _on_texture_button_mouse_entered():
	print("mouse enter")
	if !CARDTEXTUREBUTTON.disabled:
#		HOVERTIMER.start()
		if Globals.cursor_state == Globals.cursor_states.DEFAULT:
			Globals.cursor_state = Globals.cursor_states.HOVER
#			var pos = get_screen_position()
#			pos.y = 20
#			Globals.sendcursorpos.emit(pos)
		modal.emit(card_type, card_name)


func _on_texture_button_mouse_exited():
	print("mouse exit")
	if Globals.cursor_state == Globals.cursor_states.HOVER \
	and !CARDTEXTUREBUTTON.disabled:
#		HOVERTIMER.stop()
		Globals.cursor_state = Globals.cursor_states.DEFAULT
		modal.emit("", "")
#
#
#func _on_hover_timer_timeout():
#	if !CARDTEXTUREBUTTON.disabled:
#		modal.emit(card_type, card_name)

