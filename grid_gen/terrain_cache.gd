extends Resource
class_name TerrainCache

@export var size_x: int
@export var size_y: int
@export var size_z: int

@export var elevations: Array = []
@export var colors: Dictionary = {}

func get_elevation(x: int, z: int) -> float:
	return 	elevations[z * size_x + x]
	
func get_color(x: int, y: int, z: int) -> Color:
	var key = Vector3i(x,y,z)
	return colors.get(key, Color.BLACK)
