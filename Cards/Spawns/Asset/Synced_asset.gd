extends Asset

class_name SyncedAsset



var sync_pos: Vector2
var sync_dir: Vector2
var sync_offset:Vector2

var dir = Vector2()

func on_spawned():
	super()
	sync_offset = global_position-sync_pos

func _physics_process(delta):
	if Globals.game_mode == Globals.modes.MULTIPLAYER:
		if asset_owner==multiplayer.get_unique_id():
			var relative_position: Vector2 = global_position - (Globals.table_bounds.position - Globals.margin)
	#		relative_position.y 
	#		print(name, " relative position ",relative_position, " system ", multiplayer.get_unique_id())
			var flipped_position = Globals.table_bounds.end + Globals.margin + relative_position.rotated(PI) 
	#		print(name, " flipped position ",flipped_position, " system ", multiplayer.get_unique_id())
			sync_info.rpc(flipped_position,  dir.rotated(PI))
		elif fullyspawned:
			global_position = global_position.lerp(sync_pos+sync_offset, .5)
			dir = dir.lerp(sync_dir, .5)


@rpc("any_peer", "call_remote")
func sync_info(position_, dir_):
#	print("sync info recieved from:", multiplayer.get_remote_sender_id()," to ",multiplayer.get_unique_id())
#	print("player owner: ", player_owner)
	if multiplayer.get_remote_sender_id()==asset_owner:
#		print(position_)
#		print(direction_)
		sync_pos = position_
		sync_dir = dir_

