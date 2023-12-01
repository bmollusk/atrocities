extends Control

@export var Address = "127.0.0.1"
#@export var Address = "67.205.143.87"
@export var port = 8070
var peer

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		hostGame()

func peer_connected(id):
	print("Player Connected " + str(id))
	
# this get called on the server and clients
func peer_disconnected(id):
	print("Player Disconnected " + str(id))
	
# called only from clients
func connected_to_server():
	print("connected To Server!")

# called only from clients
func connection_failed():
	print("Couldnt Connect")

func hostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")

func joinGame():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func _on_join_button_pressed():
	joinGame()


func _on_host_button_pressed():
	hostGame()


func _on_start_button_pressed():
	StartGame.rpc()
	
@rpc("any_peer","call_local")
func StartGame():
	var scene = preload("res://Level/test_level.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

