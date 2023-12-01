extends ParallaxBackground


var SPRITE: AnimatedSprite2D
var SHADOW: AnimatedSprite2D
var PARALLAXLAYER: ParallaxLayer

func _ready():
	PARALLAXLAYER = $ParallaxLayer2
	SPRITE = $ParallaxLayer2/AnimatedSprite2D
	SHADOW = $ParallaxLayer2/AnimatedSprite2D2
	SPRITE.play("planning")
	SHADOW.play("default")
	
	Globals.activated.connect(on_activation)
	Globals.deactivated.connect(on_deactivation)
	
	Globals.game_end.connect(game_end_animation)

func on_activation():
	SPRITE.play("activate")
	PARALLAXLAYER.motion_scale = Vector2.ONE*2
	scroll_offset = Vector2()
	SHADOW.visible = false
	
func on_deactivation():
	SPRITE.play_backwards("activate")
	scroll_offset = Vector2()
	PARALLAXLAYER.motion_scale = Vector2.ONE*1.05


func _on_animated_sprite_2d_animation_finished():
	if SPRITE.animation == "activate":
		if Globals.active:
			SPRITE.play("activated")
		else:
			SPRITE.play("planning")
			SHADOW.visible = true
	
func game_end_animation(_win):
	await get_tree().create_timer(5).timeout
	var tween = create_tween()
	tween.tween_property(SPRITE, "modulate", Color.BLACK, 10)
	tween.parallel().tween_property(SHADOW,"modulate", Color.BLACK, 10)

