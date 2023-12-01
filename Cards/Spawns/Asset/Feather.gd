extends Projectile

var speed: float

func _ready():
	$Sprite2D2.texture = load("res://Cards/Spawns/Asset/Images/feather{0}.png".format([randi_range(1,4)]))
	if dir:
		rotation = dir.angle_to(Vector2.ONE*-1)
