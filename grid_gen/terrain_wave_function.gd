extends TerrainFunction
class_name TerrainWaveFunction

@export var amplitude: float = 2.0
@export var frequency: float = 0.2

func precalc()-> void:
	pass

# Returns elevation at integer coordinates.
func get_elevation_at(x:int, z:int) -> float:
	var fx := float(x)
	var fz := float(z)
	var h := sin(fx * frequency) * amplitude + cos(fz * frequency * 0.85) * (amplitude * 0.7)
	return h
	
	
# Returns color at coordinate (y included if needed).
func get_color_at(x:int, y:int, z:int) -> Color:
	var yf := float(y)
	var y0 := amplitude * -0.5
	var y1 := amplitude *0.25
	var y2 := amplitude* 1.2
	if yf < y0:
		return Color(0.1, 0.2, 0.6, 1.0)
	elif yf < y1:
		return  Color(0.75, 0.65, 0.45, 1.0) 
	elif yf < y2:
		return  Color(0.35, 0.6, 0.25, 1.0)
	else:
		return  Color(0.15, 0.5, 0.25, 1.0)
