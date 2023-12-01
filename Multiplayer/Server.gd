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

var peer = WebSocketMultiplayerPeer.new()

var users = {}
var lobbies = {}
@export var hostPort = 8915

var Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

func _ready():
	if "--server" in OS.get_cmdline_args():
		print("hosting on " + str(hostPort))
		startServer()
	peer.peer_connected.connect(peer_connected)
	peer.peer_disconnected.connect(peer_disconnected)

func _process(delta):
	peer.poll()
	if peer.get_available_packet_count()>0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message == Message.lobby:
				var lobbyId = data.lobbyId
				var userId = data.id
				if lobbyId=="":
					lobbyId = createLobby(userId)
				if lobbyId in lobbies:
					print("Lobby ID: ", lobbyId)
					joinLobby(userId, lobbyId)
				else:
					print("Lobby not found")
			
			if data.message == Message.offer || data.message == Message.answer || data.message == Message.candidate:
				print("source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
			
			if data.message == Message.checkIn:
				lobbies[data.lobbyId].age = 0
				
			if data.message == Message.removeLobby:
				if data.lobbyId in lobbies:
					removeLobby(data.lobbyId)

#	for lobbyId in lobbies:
#		lobbies[lobbyId].age+=delta
#		if lobbies[lobbyId].age>15:
#			print(lobbyId, " never checked in deleting... ")
#			removeLobby(lobbyId)
#		elif lobbies[lobbyId].age>10:
#			checkIn(lobbyId)
		

func peer_connected(id):
	print("Peer Connected: " + str(id))
	users[id] = {
		"id" : id,
		"message" : Message.id
	}
	sendToPlayer(id, users[id])
	var colors = []
	for lobby in lobbies:
		colors.append(lobbies[lobby].color)
	var message = {
		"message": Message.listLobbies,
		"lobbies": lobbies.keys(),
		"colors": colors
	}
	print("List lobbies")
	print(colors)
	print(lobbies.keys())
	sendToPlayer(id, message)
	
func peer_disconnected(id):
	print("Peer disconnected: ", id)
	for lobbyId in lobbies:
		if lobbies[lobbyId].hostId == id:
			removeLobby(lobbyId)
	users.erase(id)

func startServer():
	peer.create_server(hostPort)
	print("Started Server v0.11")

func createLobby(hostId):
	var lobbyId = generateRandomString()
	var color = Color.from_hsv(randf(),0.5,1).to_html()
	lobbies[lobbyId] = Lobby.new(hostId,  color)
	var message = {
		"message": Message.lobbyCreated,
		"lobbyId": lobbyId,
		"hostId": hostId,
		"color": color
	}
	sendToAll(message)
	return lobbyId

func removeLobby(lobbyId):
	lobbies.erase(lobbyId)
	var message = {
		"message": Message.lobbyRemoved,
		"lobbyId": lobbyId
	}
	sendToAll(message)

func joinLobby(userId, lobbyId):
	if lobbies[lobbyId].players.size()>=2:
		var data = {
			"message": Message.lobbyFull,
			"lobbyId": lobbyId
		}
		sendToPlayer(userId, data)
		return
	lobbies[lobbyId].addPlayer(userId, "testname")
	
	for p in lobbies[lobbyId].players:
		
		var data = {
			"message" : Message.userConnected,
			"id" : userId
		}
		sendToPlayer(p, data)
		
		var data2 = {
			"message" : Message.userConnected,
			"id" : p
		}
		sendToPlayer(userId, data2)
		
		var lobbyInfo = {
			"message" : Message.lobby,
			"players" : lobbies[lobbyId].players,
			"host" : lobbies[lobbyId].hostId,
			"lobbyId" : lobbyId,
			"color": lobbies[lobbyId].color
			
		}
		sendToPlayer(p, lobbyInfo)
	var data = {
		"message" : Message.userConnected,
		"id" : userId,
		"host" : lobbies[lobbyId].hostId,
		"player" : lobbies[lobbyId].players[userId],
		"lobbyId" : lobbyId
	}
	
	sendToPlayer(userId, data)

func checkIn(lobbyId):
	var data = {
		"message": Message.checkIn,
	}
	print("checking in to ", lobbyId, " hosted by ", lobbies[lobbyId].hostId)
	sendToPlayer(lobbies[lobbyId].hostId, data)
	
func sendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())

func sendToAll(data):
	peer.put_packet(JSON.stringify(data).to_utf8_buffer())

func generateRandomString():
	var result = ""
	for i in range(32):
		var index = randi() % Characters.length()
		result += Characters[index]
	return result

func _on_start_server_pressed():
	startServer()


func _on_test_packet_2_pressed():
	var message ={
		"message" : Message.join,
		"data" : "test message from server",
	}
	sendToAll(message)
