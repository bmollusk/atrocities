extends Node


enum Message{
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	checkIn,
	removeLobby,
	listLobbies,
	lobbyCreated, 
	lobbyRemoved,
	lobbyFull,
}

@export var ip = "159.89.88.211"


var GRIDCONTAINER: GridContainer
var MULTIPLAYERBUTTON: MultiplayerCard

var peer = WebSocketMultiplayerPeer.new()
var rtcPeer = WebRTCMultiplayerPeer.new()
var id
var hostId
var opponentId
var lobbyId
var yourLobby
var yourColor

var idxLobbies = {}

var has_connection = false



func _ready():
	
	GRIDCONTAINER = $"../MarginContainer/ScrollContainer/GridContainer"
	MULTIPLAYERBUTTON = $"../MarginContainer/MultiplayerCard"
	
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	if "--server" not in OS.get_cmdline_args():
		connectToServer()

func _exit_tree():
	if yourLobby:
		removeLobby(yourLobby)



func RTCServerConnected():
	print("RTC server connected")

func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	opponentId = id
	has_connection = true
	
	MULTIPLAYERBUTTON.disabled = false 
	MULTIPLAYERBUTTON.init("Start Game", MULTIPLAYERBUTTON.modulate.to_html())
	
func RTCPeerDisconnected(id):
	removeLobby(lobbyId)
	print("rtc peer disconnected " + str(id))
	opponentId = null
	has_connection = false
	
	MULTIPLAYERBUTTON.init("Waiting....     with lobbyId:     "+yourLobby, yourColor)


func _process(delta):
	peer.poll()
	if peer.get_available_packet_count()>0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			if data.message == Message.id:
				id = data.id
				connected(id)
				
			if data.message == Message.lobby:
				hostId = data.host
				lobbyId = data.lobbyId
				if id!=hostId:
					MULTIPLAYERBUTTON.init("connecting...", data.color)
					MULTIPLAYERBUTTON.disabled = true
				print(id," joined lobby ", lobbyId, " with host ", hostId)
				
			if data.message == Message.lobbyFull:
				lobbyFull(data.lobbyId)
			
			if data.message == Message.userConnected:
				createPeer(data.id)
				
			if data.message == Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got Candididate: " + str(data.orgPeer) + " my id is " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			
			if data.message == Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			
			if data.message == Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)
				
			if data.message == Message.listLobbies:
				showLobbies(data.lobbies, data.colors)
			
			if data.message == Message.lobbyCreated:
				addLobbyToList(data.lobbyId, data.color, data.hostId)
			
			if data.message == Message.lobbyRemoved:
				removeLobbyFromList(data.lobbyId)
				
			if data.message == Message.checkIn:
				checkIn()

func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer
	
	joinLobby(id, "")

func lobbyFull(id):
	for lobbycard in GRIDCONTAINER.get_children():
		if lobbycard.lobbyId == id:
			lobbycard.disabled = true
			lobbycard.set_text("Lobby Full")

func connectToServer():
	peer.create_client("ws://"+ip+":8915")
	print("started client")

func createPeer(id):
	if id != self.id:
		var peer = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})
		print("binding id " + str(id) + "my id is " + str(self.id))
		
		peer.session_description_created.connect(offerCreated.bind(id))
		peer.ice_candidate_created.connect(iceCandidateCreated.bind(id))
		rtcPeer.add_peer(peer, id)
		
		if id<rtcPeer.get_unique_id():
			peer.create_offer()
		

func offerCreated(type, data, id):
	if !rtcPeer.has_peer(id):
		return
		
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)
	
	
func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.offer,
		"data": data,
		"Lobby": lobbyId
	}
	sendToServer(message)
	pass

func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.answer,
		"data": data,
		"Lobby": lobbyId
	}
	sendToServer(message)
	pass

func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"Lobby": lobbyId
	}
	sendToServer(message)
	pass


func _on_test_packet_pressed():
	var message ={
		"message" : Message.join,
		"data" : "test",
	}
	sendToServer(message)

func sendToServer(message):
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func showLobbies(lobbies, colors):
	for child in GRIDCONTAINER.get_children():
		child.queue_free()
	for i in range(lobbies.size()):
		addLobbyToList(lobbies[i], colors[i])

func addLobbyToList(lobbyId, color, hostId_=null):
	if hostId_ and not yourLobby and hostId_==id:
		yourLobby = lobbyId
		yourColor = color
		MULTIPLAYERBUTTON.init("Waiting....     with lobbyId:     "+lobbyId, color)
		MULTIPLAYERBUTTON.disabled = true
	else:
		var lobbycard: MultiplayerCard = preload("res://GUI/multiplayer_card.tscn").instantiate()
		lobbycard.init(lobbyId, color)
		lobbycard.pressed.connect(Callable(item_clicked).bind(lobbycard.lobbyId))
		GRIDCONTAINER.add_child(lobbycard)

func removeLobbyFromList(lobbyId):
	for child in GRIDCONTAINER.get_children():
		if child.lobbyId == lobbyId:
			child.queue_free()


func joinLobby(userId, lobbyId):
	var message = {
			"message" : Message.lobby,
			"id": userId,
			"lobbyId": lobbyId
		}
	sendToServer(message)

func checkIn():
	var message = {
		"message": Message.checkIn,
		"lobbyId": lobbyId
	}
	sendToServer(message)

func removeLobby(lobbyId):
	var message = {
			"message" : Message.removeLobby,
			"lobbyId": lobbyId
		}
	sendToServer(message)

func _on_join_lobby_pressed():
	joinLobby(id,$"../Client2/LineEdit".text )


func item_clicked(lobbyId_):
	joinLobby(id, lobbyId_)

func _on_item_list_item_clicked(index, at_position, mouse_button_index):
	var lobid = idxLobbies.find_key(index)
	joinLobby(id, lobid)

func _on_ping_pressed():
	ping.rpc()

@rpc("any_peer")
func ping():
	print("ping from: "+ str(multiplayer.get_remote_sender_id()))


func _on_button_pressed():
#	if has_connection:
	StartGame.rpc()

@rpc("any_peer","call_local")
func StartGame():
	get_parent().visible = false
	Globals.P1 = hostId
	Globals.opponent = opponentId
	removeLobby(lobbyId)
	if lobbyId!=yourLobby:
		removeLobby(yourLobby)
	var scene = preload("res://Level/test_level.tscn").instantiate()
	get_tree().root.add_child(scene)



func _on_back_button_pressed():
	get_tree().change_scene_to_packed(Globals.home)
