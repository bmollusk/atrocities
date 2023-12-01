extends IngameCard

var speedable = []
var used = false

func default_ingame_opened_func(ingame: Node2D):
	var spawns = ingame.find_child("Spawns")
	for spawn in spawns.get_children():
		on_every_spawn_func(spawn)
	var fixedrot = Globals.if_norot(rotation, card_owner)
	fixedrot = Globals.fix_neg_rot(fixedrot)
	var time = remap(fixedrot, 0, 2*PI, 10, 30)
	print("time slow started ", time, " with factor ", 3*scale.x)
	AudioServer.playback_speed_scale/=3*scale.x
	$EffectTimer.start(time)

func on_every_spawn_func(spawn: Node2D):
	if eye_open and not used:
		if  "SPEED" in spawn or "speed" in spawn:
			speedable.append(spawn)
			var loading: Array[Node] = spawn.find_children("loading*", "Sprite2D", true, false)
			var loadingimg = $loading.duplicate()
			loadingimg.visible = true
			if loading.size()>0:
				loadingimg.name = "loading"+str(loading.size())
				loadingimg.position += Vector2.ONE
			spawn.add_child(loadingimg)
			print(speedable)
		if "SPEED" in spawn:
			spawn.SPEED/=3*scale.x
		if "speed" in spawn:
			spawn.speed/=3*scale.x

func default_ingame_destroyed_func(ingame: Node2D):
	remove_effect()

func remove_effect():
	print("slowdown removed")
	for spawn in speedable:
		if not is_instance_valid(spawn):
			continue
		var loading: Array[Node] = spawn.find_children("loading*", "Sprite2D", true, false)
		loading[-1].queue_free()
		if "SPEED" in spawn:
			spawn.SPEED*=3*scale.x
		if "speed" in spawn:
			spawn.speed*=3*scale.x
	AudioServer.playback_speed_scale*=3*scale.x
	speedable = []

func _on_effect_timer_timeout():
	used = true
	remove_effect()

