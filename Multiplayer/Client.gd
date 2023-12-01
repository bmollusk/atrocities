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
	lobbyRemoved
}
@export var ip = "159.89.88.211"


var peer = WebSocketMultiplayerPeer.new()
var rtcPeer = WebRTCMultiplayerPeer.new()
var id
var hostId
var opponentId
var lobbyId

var idxLobbies = {}

var has_connection = false

func _ready():
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)



func RTCServerConnected():
	print("RTC server connected")

func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	opponentId = id
	has_connection = true
	
func RTCPeerDisconnected(id):
	removeLobby(lobbyId)
	print("rtc peer disconnected " + str(id))
	opponentId = null
	has_connection = false


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
				showLobbies(data.lobbies)
			
			if data.message == Message.lobbyCreated:
				addLobbyToList(data.lobbyId)
			
			if data.message == Message.lobbyRemoved:
				removeLobbyFromList(data.lobbyId)
				

func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer

func connectToServer():
	peer.create_client("ws://"+ip+":8915")
	print("started client")
	

func _on_start_client_pressed():
	connectToServer()

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
		
		if !hostId == self.id:
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

func showLobbies(lobbies):
	$"../ItemList".clear()
	for key in lobbies:
		addLobbyToList(key)

func addLobbyToList(lobbyId):
	var idx = $"../ItemList".add_item(lobbyId)
	idxLobbies[lobbyId] = idx

func removeLobbyFromList(lobbyId):
	var idx = idxLobbies[lobbyId]
	$"../ItemList".remove_item(idx)



func joinLobby(userId, lobbyId):
	var message = {
			"message" : Message.lobby,
			"id": userId,
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
	$"..".visible = false
	Globals.P1 = hostId
	Globals.opponent = opponentId
	removeLobby(lobbyId)
	var scene = preload("res://Level/test_level.tscn").instantiate()
	get_tree().root.add_child(scene)


func _on_item_list_item_clicked(index, at_position, mouse_button_index):
	$"../Client2/LineEdit".text = $"../ItemList".get_item_text(index)
