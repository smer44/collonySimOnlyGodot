extends AbstractTerrainElevationGenerator
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
	
