extends Node2D

var fired = false
var targets = []
var default = Vector2(-22,-22)
signal placed(type, cardname, ui_placed_func: Callable, ingame_placed_func: Callable)


func _ready():
	Globals.cursor_state = Globals.cursor_states.CARD

func _process(delta):
	if Input.is_action_just_pressed("Action"):
		if len(targets)>0:
			fired = true
			var tween = create_tween()
			tween.tween_method(targets[-1].get_parent().modulate_card_rpc, Color.WHITE, Color.RED, 1)
			tween.tween_method(targets[-1].get_parent().modulate_card_rpc,Color.RED, Color.WHITE, 0.5)
			tween.tween_method(targets[-1].get_parent().modulate_card_rpc, Color.WHITE, Color.RED, 0.25)
			tween.tween_callback(kill_card)
	if len(targets)>0:
		$Sprite2D.global_position = targets[-1].global_position
	else:
		$Sprite2D.position = default
	position = get_global_mouse_position()

func _on_area_2d_area_entered(area: Area2D):
	if not fired:
		targets.append(area)


func _on_area_2d_area_exited(area):
	if not fired:
		targets.erase(area)

func kill_card():
	targets[-1].get_parent().destroy.rpc()
#	placed.emit("Effect", "Burned", Callable(), Callable())
	Globals.cursor_state = Globals.cursor_states.DEFAULT
	queue_free()
