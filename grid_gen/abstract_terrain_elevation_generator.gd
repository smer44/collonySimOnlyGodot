extends Resource
class_name AbstractTerrainElevationGenerator



# Returns elevation at integer coordinates.
func get_elevation_at(x:int, z:int) -> float:
	push_error("AbstractTerrainElevationGenerator.get_elevation_at must be implemented in subclass: %s" % self)
	return 0.0
	
func precalc()-> void:
	push_error("AbstractTerrainElevationGenerator.precalc must be implemented in subclass: %s" % self)
	
	
