extends Projectile


func _ready():
	rotation = dir.angle_to(Vector2.UP)
