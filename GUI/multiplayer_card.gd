extends TextureButton

class_name MultiplayerCard

var lobbyId;


func init(lobbyId_, color_):
	lobbyId = lobbyId_
	$Label.text = lobbyId
	modulate = Color.from_string(color_, Color.WHITE)

func set_text(text):
	$Label.text = text
