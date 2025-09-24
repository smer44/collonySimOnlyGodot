extends Resource
class_name TerrainFunction



# Returns elevation at integer coordinates.
func get_elevation_at(x:int, z:int) -> float:
	push_error("TerrainFunction.get_elevation_at must be implemented in subclass: %s" % self)
	return 0.0
	
func precalc()-> void:
	push_error("TerrainFunction.precalc must be implemented in subclass: %s" % self)
	
	
# Returns color at coordinate (y included if needed).
func get_color_at(x:int, y:int, z:int) -> Color:
	push_error("TerrainFunction.get_color_at must be implemented in subclass : %s" % self)
	return Color.RED
