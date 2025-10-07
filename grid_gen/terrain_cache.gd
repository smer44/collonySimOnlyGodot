extends AbstractTerrainElevationGenerator
class_name TerrainCache

@export var size_x: int
@export var size_y: int
@export var size_z: int

@export var elevations: Array = []

func precalc():
	pass

func get_elevation_at(x: int, z: int) -> float:
	var pos:= z * size_x + x
	if pos < 0 or pos > elevations.size():
		return 0.0
	return 	elevations[pos]
	
