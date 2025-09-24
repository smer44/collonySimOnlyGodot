# Grid2D resource definition
class_name Array2D
extends Resource


@export var grid: Array[Array] = []


func shape() -> Vector2i:
	var width := grid.size()
	if width == 0:
		return Vector2i.ZERO
	var height := grid[0].size()
	return Vector2i(width,height)
	
	
func instance_count() -> int:
	var shp := shape()
	return shp.x * shp.y 
	
