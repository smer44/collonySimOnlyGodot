extends TerrainFunction
class_name TerrainPathfindfunction

#this class will "mark" path found on the given terrain by its elevation.
#the pathfind is done in precalc.



var find_algo := AStarMy.new()
@export var terrain : TerrainFunction
@export var start := Vector2i(0,0)
@export var goal := Vector2i(0,0)
@export var bounds_start := Vector2i.ZERO
@export var bounds_inclusive := Vector2i(31,31)
var path := {}

func get_elevation_at(x:int, z:int) -> float:
	#push_error("TerrainFunction.get_elevation_at must be implemented in subclass: %s" % self)
	return terrain.get_elevation_at(x,z)
	
func precalc()-> void:
	#push_error("TerrainFunction.precalc must be implemented in subclass: %s" % self)
	terrain.precalc()
	var path_array :Array= find_algo.find(terrain,start,goal, bounds_start, bounds_inclusive)
	path.clear()
	for p in path_array:
		path[p] = true 
		
	
	
	
# Returns color at coordinate (y included if needed).
func get_color_at(x:int, y:int, z:int) -> Color:
	#push_error("TerrainFunction.get_color_at must be implemented in subclass : %s" % self)
	var p := Vector2i(x,z)
	if p in path:
		return Color.RED
	return terrain.get_color_at(x,y,z)
	
	
		
