extends Projectile


func _ready():
	$Sprite2D.texture = load("res://Cards/Spawns/Asset/Images/balloonpart{0}.png".format([randi_range(1,4)]))
