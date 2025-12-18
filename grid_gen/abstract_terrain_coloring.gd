extends Resource
class_name AbstractTerrainColoring

var terrain_generator : AbstractTerrainElevationGenerator 
# Returns color at coordinate (y included if needed).
func get_color_at(x:int, y:int, z:int) -> Color:
	push_error("AbstractTerrainColoring.get_color_at must be implemented in subclass : %s" % self)
	return Color.RED


	
func precalc_for(terrain_generator : AbstractTerrainElevationGenerator ) -> void:
	self.terrain_generator = terrain_generator

	
	
