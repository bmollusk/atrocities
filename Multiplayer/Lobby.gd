extends RefCounted
class_name Lobby

var hostId : int
var color: String
var players : Dictionary = {}
var age = 0



func _init(id, color_):
	hostId = id
	color = color_
	
func addPlayer(id, name):
	players[id] = {
		"name": name,
		"id": id,
		"index": players.size() + 1
	}
	return players[id]
