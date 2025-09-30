extends Resource
class_name AbstractTerrainColoring


# Returns color at coordinate (y included if needed).
func get_color_at(x:int, y:int, z:int) -> Color:
	push_error("AbstractTerrainColoring.get_color_at must be implemented in subclass : %s" % self)
	return Color.RED

func precalc()-> void:
	push_error("AbstractTerrainColoring.precalc must be implemented in subclass: %s" % self)
	
	
