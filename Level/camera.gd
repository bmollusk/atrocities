extends Node2D


var focus = self:
	set(value):
		tween.tween_property(self, "camera_position", value.global_position, 2).from(focus.global_position)
		focus = value
	get:
		return focus
var zoom = Vector2.ONE:
	set(value):
		tween.tween_property($Camera2D, "zoom", value, tween_duration).from(zoom)
		zoom = value
	get:
		return zoom
var camera_position = Vector2.ZERO
var mouse_influence_val = 1:
	set(value):
		tween.tween_property(self, "mouse_influence", value, tween_duration).from(mouse_influence_val)
		mouse_influence_val = value
	get:
		return mouse_influence
var mouse_influence = 1
var tween_duration = 2
var tween: Tween:
	set(value):
		tween = value
	get:
		if tween and tween.is_valid():
			return tween
		else:
			tween = create_tween()
			tween.set_parallel(true)
			return tween
		


# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.game_end.connect(end_anim)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if focus and is_instance_valid(focus):
		camera_position = focus.global_position
		var mouse_offset = (get_viewport().get_mouse_position() - Vector2(get_viewport().size / 2))
		global_position = lerp(camera_position, mouse_offset, 0.4*mouse_influence)

func end_anim(_win):
	tween.tween_property(self, "mouse_influence", 0, tween_duration)
