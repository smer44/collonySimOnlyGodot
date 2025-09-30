@tool
extends Node
class_name TerrainBaker

@export var function: TerrainSmartFunction
@export var size_x: int = 64
@export var size_y: int = 16
@export var size_z: int = 64

func bake_to_cache(path: String):
	if function == null:
		push_error("No function assigned!")
		return
	
	var cache := TerrainCache.new()
	cache.size_x = size_x
	cache.size_y = size_y
	cache.size_z = size_z
	
	cache.elevations.resize(size_x * size_z)
	
	for z in size_z:
		for x in size_x:
			var elev = function.get_elevation_at(x, z)
			cache.elevations[z * size_x + x] =elev
			
			for y in size_y:
				var color = function.get_color_at(x, y, z)
				if color != Color.BLACK:
					cache.colors[Vector3i(x, y, z)] = color
	
	ResourceSaver.save(cache, path)
