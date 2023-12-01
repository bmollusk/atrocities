extends Node2D

class_name AIController

var bodies_visible = []
var areas_visible = []
@export var ai_parent: GameAI
@export var cell_size = 16

var scoreeqs;

var destroy_key = false

var stops = {}

@export var astar_grid: AStar2DGridNode;
var astar_obid = []

var player: Player

func init_info(playerspawn: Player):
	astar_grid.cell_size = Vector2.ONE*cell_size
	astar_grid.global_position = Globals.table_bounds.position
	astar_grid.grid_size = round(Globals.table_bounds.size/astar_grid.cell_size)
	astar_grid.enable_debug = true
	player = playerspawn

func get_vector()->Vector2:
	return Vector2.DOWN

func destroy_key_pressed()->bool:
	return destroy_key

func _on_visible_area_body_entered(body):
	bodies_visible.append(body)


func _on_visible_area_body_exited(body):
	bodies_visible.erase(body)
#	if astar_grid:
#		astar_grid.set_point_solid(snapped(body.global_position/16, Vector2.ONE), false)


func _on_visible_area_area_entered(area):
	areas_visible.append(area)


func _on_visible_area_area_exited(area):
	areas_visible.erase(area)

func score_from_tags(str_):
	var tags = []
	if str_ in Globals.ai_tags:
		tags = Globals.ai_tags[str_]
	var score = 0
	for tag in tags:
		if tag in scoreeqs:
			score+=scoreeqs[tag]
	return score

func add_stop(str_, score, pos):
	stops[str_] = [score, pos]
