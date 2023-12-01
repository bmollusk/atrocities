extends Asset

var damage = 1

func init(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id):
	super(card_, s_type, s_cardname, s_scale, s_rotate, s_translate, id)
	apply_scale(spawn_scale*Vector2.ONE)
	if randi()%10!=1:
		damage = 0
	var protate = spawn_rotate
	if protate<0:
		protate = 2*PI-protate
	var remapped = remap(spawn_rotate, 0, 2*PI, 0, 16)
	$Sprite2D.frame = snapped(remapped, 1)

