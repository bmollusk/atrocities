extends Node2D

class_name IngameCard

var card_owner;

var card_opener; 

var card_visible = false
var eye_open = false
var active = false
enum {TRANSLATING, SCALING, ROTATING, PLACING, PLACED}
var transform_state = TRANSLATING
var rotate_start: Vector2;


const SPAWN_SCALE = 0.12

var card_type;
var card_name;
var card_texture: Texture2D;
var back_card_texture: Texture2D
var back_card_open_texture: Texture2D
var tween: Tween

signal placed(type, cardname, ui_placed_func: Callable, ingame_placed_func: Callable, position_, scale_, rotation_)

signal opened(type, cardname, ui_opened_func: Callable, ingame_opened_func: Callable)
signal shown(type, cardname, ui_shown_func: Callable, ingame_shown_func: Callable)
signal entered(type, cardname, ui_entered_func: Callable, ingame_entered_func: Callable)
signal exited(type, cardname, ui_exited_func: Callable, ingame_exited_func: Callable)
signal spawned(type, cardname, ui_spawned_func: Callable, ingame_spawned_func: Callable, spawn: Node2D)
signal spawn_destroyed(type, cardname, ui_spawn_destroyed_func: Callable, ingame_spawn_destroyed_func: Callable, spawn: Node2D)
signal destroyed(type, cardname, ui_destroyed_func: Callable, ingame_destroyed_func: Callable)

var SPAWN: Sprite2D
var SPRITE: Sprite2D
var OVERLAYSPRITE: AnimatedSprite2D
var OVERLAYPLAYER: AnimationPlayer
var PARTICLES: GPUParticles2D
var TRANSLATEAUDIO: AudioStreamPlayer2D
var SCALEAUDIO: AudioStreamPlayer2D
var ROTATEAUDIO: AudioStreamPlayer2D
var PLACEAUDIO: AudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func init_card(type, cardname, playerid):
	SPAWN = $Spawn
	SPAWN.visible = false
	SPRITE = $Sprite2D
	OVERLAYSPRITE = $Sprite2D/AnimatedSprite2D
	OVERLAYSPRITE.visible = false
	OVERLAYPLAYER = $Sprite2D/AnimatedSprite2D/AnimationPlayer
	PARTICLES = $GPUParticles2D
	TRANSLATEAUDIO = $TranslateAudio
	SCALEAUDIO = $ScaleAudio
	ROTATEAUDIO = $RotateAudio
	PLACEAUDIO = $PlaceAudio
	if playerid == Globals.P1:
		back_card_open_texture = load("res://Cards/Images/BackOpen.jpg")
		back_card_texture = load("res://Cards/Images/Back.jpg")
	else:
		back_card_open_texture = load("res://Cards/Images/Back2Open.jpg")
		back_card_texture = load("res://Cards/Images/Back2.jpg")
	var pathstring = "res://Cards/Images/{0}/{1}.jpg"
	card_texture = load(pathstring.format([type,cardname]))
	SPRITE.set_texture(back_card_texture)
	card_type = type
	card_name = cardname 
	card_owner = playerid
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("Action"):
		if transform_state == TRANSLATING:
			Globals.cursor_state = Globals.cursor_states.SCALE
			SCALEAUDIO.play()
		if transform_state == SCALING:
			rotate_start = position.direction_to(get_global_mouse_position())
			Globals.cursor_state = Globals.cursor_states.ROTATE
			ROTATEAUDIO.play()
		if transform_state == ROTATING:
			Globals.cursor_state = Globals.cursor_states.DEFAULT
			play_audio(PLACEAUDIO, 1, 0.5)
		if transform_state < PLACING:
			transform_state+=1
	if transform_state == TRANSLATING:
		var position_snapped = Globals.snap_pos(get_global_mouse_position())
		if position != position_snapped and !TRANSLATEAUDIO.playing:
			var pitch = remap(position_snapped.x, \
			Globals.table_bounds.position.x, Globals.table_bounds.end.x, \
			1, 1.5)
			play_audio(TRANSLATEAUDIO, pitch)
		position = position_snapped
	if transform_state == SCALING:
		var scale_float = position.distance_to(get_global_mouse_position())
		scale_float = Globals.snap_scale(scale_float)
		if scale != Vector2.ONE*scale_float and !SCALEAUDIO.playing:
			var pitch = remap(scale_float, 1,2, 1.5, 1)
			play_audio(SCALEAUDIO, pitch)
		scale = Vector2.ONE*scale_float
		queue_redraw()
	if transform_state == ROTATING:
		var rotate_end = position.direction_to(get_global_mouse_position())
		var rotate_radians = rotate_start.angle_to(rotate_end)
		rotate_radians = Globals.snap_rot(rotate_radians)
		if !is_equal_approx(rotation, rotate_radians) and !ROTATEAUDIO.playing:
			var pitch = remap(rotate_radians, 0, 2*PI, 1, 2)
			play_audio(ROTATEAUDIO, pitch)
		rotation = rotate_radians
		queue_redraw()
	if transform_state == PLACING:
		queue_redraw()
		place()

func play_audio(audio: AudioStreamPlayer2D, pitch: float, start_pos:float = 0):
	audio.pitch_scale = pitch
	audio.volume_db = remap(position.y, Globals.table_bounds.position.y,Globals.table_bounds.end.y,\
	 -1,1)
	audio.play(start_pos)

func _draw():
	if transform_state == SCALING:
		var radius = get_local_mouse_position().length()
		radius = clampf(radius, Globals.MIN_SCALE/scale.x, Globals.MAX_SCALE/scale.x)
#		var scaled_radius = radius*scale.x
		draw_unfilled_circle(Vector2.ZERO, radius, Color.AQUA)
		draw_unfilled_circle(Vector2.ZERO, Globals.MIN_SCALE, Color.AQUAMARINE)
		draw_unfilled_circle(Vector2.ZERO, Globals.MIN_SCALE/scale.x, Color.DARK_RED)
		draw_unfilled_circle(Vector2.ZERO, Globals.MAX_SCALE/scale.x, Color.DARK_RED)
	if transform_state == ROTATING:
		var line_length = get_local_mouse_position().length()
		var line_rot = Vector2.RIGHT.angle_to(get_local_mouse_position())
		draw_line(Vector2.ZERO, Vector2.from_angle(line_rot)*line_length, Color.AQUA)
		draw_line(Vector2.ZERO, rotate_start.rotated(Globals.ROTATE_SNAP/2)*line_length, Color.DARK_RED)
		draw_line(Vector2.ZERO, rotate_start.rotated(-Globals.ROTATE_SNAP/2)*line_length, Color.DARK_RED)

func draw_unfilled_circle(center: Vector2, radius: float, color: Color):
		draw_arc(center, radius, 0, 2*PI, 20, color)

func set_placed(position_=null, scale_=null, rotation_=null):
	if position_:
		position = position_
	if scale_:
		scale = scale_
	if rotation_:
		rotation = rotation_
	transform_state=PLACED
	active = Globals.active

func place(type=card_type, cardname=card_name):
	set_placed()
	var pos = get_global_transform_with_canvas().origin
	Globals.sendcursorpos.emit(pos)
	placed.emit(type, cardname, default_ui_placed_func, default_ingame_placed_func, position, scale, rotation)

func modulate_card_rpc(color: Color):
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		modulate_card.rpc(color)
	elif Globals.game_mode == Globals.modes.AI:
		modulate_card(color)

@rpc("any_peer", "call_local")
func modulate_card(color: Color):
	SPRITE.self_modulate = color


func default_ui_placed_func(_ui: Control):
	pass

func default_ingame_placed_func(_ingame: Node2D):
	pass
	
func default_ui_opened_func(_ui: Control):
	pass

func default_ingame_opened_func(_ingame: Node2D):
	pass

func default_ui_shown_func(_ui: Control):
	pass

func default_ingame_shown_func(_ingame: Node2D):
	pass

func default_ui_entered_func(_ui: Control):
	pass

func default_ingame_entered_func(_ingame: Node2D):
	pass

func default_ui_exited_func(_ui: Control):
	pass

func default_ingame_exited_func(_ingame: Node2D):
	pass

func default_ui_spawned_func(_ui: Control):
	pass

func default_ingame_spawned_func(_ingame: Node2D):
	pass

func default_ui_spawn_destroyed_func(_ui: Control):
	pass

func default_ingame_spawn_destroyed_func(_ingame: Node2D):
	pass

func default_ui_destroyed_func(_ui: Control):
	pass

func default_ingame_destroyed_func(_ingame: Node2D):
	pass

func on_every_spawn_func(_spawnscene: Node2D):
	pass


func activate():
	active = true
	if card_type!="Player":
		open_eye()
		await get_tree().create_timer(0.5).timeout
		show_card()
	
func deactivate():
	active = false
	hide_card()

func spawn(type=card_type, \
		cardname=card_name, \
		ui_spawned_func=default_ui_spawned_func, \
		ingame_spawned_func=default_ingame_spawned_func):
	if OVERLAYPLAYER.is_playing():
		OVERLAYPLAYER.stop()
#		print("stopped")
	OVERLAYPLAYER.play("new_animation", -1, 0.5)
#	print(OVERLAYPLAYER.assigned_animation)
	var pathstring = "res://Cards/Spawns/{0}/{1}.tscn".format([card_type,card_name.to_snake_case()])
	if ResourceLoader.exists(pathstring):
		var spawnscene:Node2D = load(pathstring).instantiate()
		var rotation_ = rotation
		if "norot" in spawnscene and spawnscene.norot:
			rotation_ = Globals.if_norot(rotation_, card_owner)
		spawnscene.init(self, type, cardname, scale, rotation_, position, card_owner)
		spawnscene.destroyed.connect(Callable(destroy_spawn).bind(spawnscene))#TODOSPAWN
#		SPAWN.call_deferred("add_child", spawnscene)
		SPAWN.global_rotation = 0
		SPAWN.global_scale = Vector2.ONE*SPAWN_SCALE
		SPAWN.add_child(spawnscene)
		
#		SPAWN.texture = load("res://Overlays/Mask.png")
		SPAWN.visible = true
		SPAWN.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		if tween and tween.is_valid() and tween.is_running():
			tween.kill()
		tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_parallel()
		var spriteheight = spawnscene.sprite_y_bounds()
		var spritetraveltime = (spriteheight[1]+spriteheight[0])*-0.005
		tween.tween_property(spawnscene, "visible", true,1).from(true)
		tween.tween_property(spawnscene, "position", Vector2(0,spriteheight[0]), spritetraveltime)\
		.from(Vector2(0,-spriteheight[1]))
		tween.chain().tween_callback(func(): SPAWN.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED)
#		tween.tween_callback(func(): SPAWN.texture = null)
		tween.tween_callback(func(): SPAWN.visible = false)
		tween.chain().tween_callback(func(): spawned.emit(type, cardname, ui_spawned_func, ingame_spawned_func, spawnscene))
		if "on_spawned" in spawnscene:
			tween.tween_callback(spawnscene.on_spawned)
		return spawnscene
	return null
 


func destroy_spawn(spawnscene: Node2D, \
		type=card_type, \
		cardname=card_name, \
		ui_spawn_destroyed_func=default_ui_spawn_destroyed_func, \
		ingame_spawn_destroyed_func=default_ingame_spawn_destroyed_func):
	spawn_destroyed.emit(type, cardname, ui_spawn_destroyed_func, ingame_spawn_destroyed_func, spawnscene)
	if card_type!="Player":
		show_card.call_deferred()
#		show_card.rpc()

@rpc("any_peer", "call_local")
func destroy(type=card_type, \
		cardname=card_name, \
		ui_destroyed_func=default_ui_destroyed_func, \
		ingame_destroyed_func=default_ingame_destroyed_func):
#	var orphanage = find_parent("Table").find_child("Orphan")
#	for spawned in SPAWN.get_children():
#		spawned.reparent(orphanage)
#		spawned.destroyed.connect(func(): Globals.deactivated.emit())
	if SPAWN.get_child_count()==0:
		PARTICLES.emitting = true
		SPRITE.visible = false
		await get_tree().create_timer(0.5).timeout
		destroyed.emit(type, cardname, ui_destroyed_func, ingame_destroyed_func)
	
@rpc("any_peer", "call_remote")
func show_card(type=card_type, \
		cardname=card_name, \
		ui_shown_func=default_ui_shown_func, \
		ingame_shown_func=default_ingame_shown_func):
	card_visible = true
#	print(OVERLAYPLAYER.assigned_animation)
	shown.emit(type, cardname, ui_shown_func, ingame_shown_func)
	return spawn()#TODOSPAWN

func flip_card_texture():
	SPRITE.set_texture(card_texture)

@rpc("any_peer","call_remote")
func open_eye(type=card_type, \
		cardname=card_name, \
		ui_opened_func=default_ui_opened_func, \
		ingame_opened_func=default_ingame_opened_func):
	SPRITE.set_texture(back_card_open_texture)
	eye_open = true
	opened.emit(type, cardname, ui_opened_func, ingame_opened_func)

func card_entered(type=card_type, \
		cardname=card_name, \
		ui_entered_func=default_ui_entered_func, \
		ingame_entered_func=default_ingame_entered_func):
	entered.emit(type, cardname, ui_entered_func, ingame_entered_func)

func card_exited(type=card_type, \
		cardname=card_name, \
		ui_exited_func=default_ui_exited_func, \
		ingame_exited_func=default_ingame_exited_func):
	exited.emit(type, cardname, ui_exited_func, ingame_exited_func)

func _on_area_2d_body_entered(body):
	print("body entered by ", body)
	if active and not eye_open and not card_visible and card_type!="Player":
		var multiplayer_condition = body.player_owner==multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER
		var ai_condition = Globals.game_mode == Globals.modes.AI
		if "player_owner" in body and (multiplayer_condition or ai_condition):
			card_opener = body.player_owner
			print("card opener is ", card_opener)
			open_eye()
			if multiplayer_condition:
				open_eye.rpc()
		elif "player_owner" not in body:
			open_eye()
			if Globals.game_mode == Globals.modes.MULTIPLAYER:
				open_eye.rpc()
	elif active and card_visible:
		if "entered_card" in body:
			body.entered_card(self)
		card_entered()

func _on_area_2d_body_exited(body):
	print("body entered by ", body)
	if active and not card_visible and eye_open and card_type!="Player":
#		call_deferred("show_card")#TODOWPAWN
		var multiplayer_condition = body.player_owner==multiplayer.get_unique_id() and Globals.game_mode == Globals.modes.MULTIPLAYER
		var ai_condition = Globals.game_mode == Globals.modes.AI
		if (card_opener and body.player_owner==card_opener and (multiplayer_condition or ai_condition))\
		or not card_opener:
			show_card.call_deferred()
			if multiplayer_condition:
				show_card.rpc()
			
	elif active:
		if "exited_card" in body:
			body.exited_card(self)
		card_exited()

func despawn():
	for spawnscene in SPAWN.get_children():
		spawnscene.queue_free()

func hide_card():
	eye_open = false
	card_visible = false
	OVERLAYPLAYER.stop()
	OVERLAYSPRITE.visible = false
	SPRITE.set_texture(back_card_texture)
	despawn()




func _on_area_2d_area_entered(area):
	print("card_owner" in area.get_parent())
